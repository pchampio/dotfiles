#!/usr/bin/env python3
"""Local microphone UI and SSH relay for the persistent parakeet.cpp service.

Wire format: newline-delimited JSON, PCM signed 16-bit little endian, mono 16kHz.
No audio or transcript is stored on disk.
"""
import argparse
import base64
import ctypes as C
import curses
import json
import math
import os
from pathlib import Path
import queue
import re
import selectors
import shutil
import socket
import socketserver
import struct
import subprocess
import sys
import tempfile
import threading
import time

MAX_LINE = 65536
BLOCK = 3200  # 100ms of s16le audio


def socket_path():
    return str(Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'parakeet-voice.sock')


def emit(output, message):
    output.write((json.dumps(message, ensure_ascii=True) + '\n').encode())
    output.flush()


def read_message(source):
    line = source.readline(MAX_LINE + 1)
    if not line:
        raise EOFError('Connection closed before transcription finished')
    if len(line) > MAX_LINE or not line.endswith(b'\n'):
        raise ValueError('Invalid or oversized protocol message')
    result = json.loads(line)
    if not isinstance(result, dict):
        raise ValueError('Expected a JSON object')
    return result


class Model:
    def __init__(self, library, model):
        os.environ['PARAKEET_DEVICE'] = 'cpu'
        self.lib = C.CDLL(library)
        signatures = {
            'load': ([C.c_char_p], C.c_void_p),
            'free': ([C.c_void_p], None),
            'last_error': ([C.c_void_p], C.c_char_p),
            'free_string': ([C.c_void_p], None),
            'stream_begin_lang': ([C.c_void_p, C.c_char_p], C.c_void_p),
            'stream_free': ([C.c_void_p], None),
            'stream_feed_json': ([C.c_void_p, C.POINTER(C.c_float), C.c_int], C.c_void_p),
            'stream_finalize_json': ([C.c_void_p], C.c_void_p),
        }
        for name, (args, result) in signatures.items():
            fn = getattr(self.lib, 'parakeet_capi_' + name)
            fn.argtypes, fn.restype = args, result
            setattr(self, name, fn)
        self.ctx = self.load(os.fsencode(model))
        if not self.ctx:
            raise RuntimeError('Cannot load model; see parakeet diagnostics above')

    def checked(self, pointer):
        if not pointer:
            raise RuntimeError(self.last_error(self.ctx).decode())
        return pointer

    def result(self, pointer):
        self.checked(pointer)
        try:
            return json.loads(C.string_at(pointer))['text']
        finally:
            self.free_string(pointer)

    def feed(self, stream, raw):
        if not raw or len(raw) % 2 or len(raw) > 32000:
            raise ValueError('Expected at most one second of s16le audio')
        values = struct.unpack('<' + 'h' * (len(raw) // 2), raw)
        pcm = (C.c_float * len(values))(*(x / 32768 for x in values))
        return self.result(self.stream_feed_json(stream, pcm, len(values)))


def serve(args):
    model = Model(args.library, args.model)
    lock = threading.Lock()

    class Handler(socketserver.StreamRequestHandler):
        def handle(self):
            self.connection.settimeout(30)
            if not lock.acquire(blocking=False):
                emit(self.wfile, {'error': 'Another recording is using the model'})
                return
            stream = None
            try:
                request = read_message(self.rfile)
                if request.get('type') != 'start':
                    raise ValueError('Expected start')
                stream = model.checked(model.stream_begin_lang(model.ctx, request.get('lang', 'en-US').encode()))
                emit(self.wfile, {'type': 'ready'})
                samples = 0
                while True:
                    request = read_message(self.rfile)
                    if request.get('type') == 'ping':
                        emit(self.wfile, {'type': 'pong'})
                        continue
                    if request.get('type') == 'stop':
                        emit(self.wfile, {'type': 'done', 'text': model.result(model.stream_finalize_json(stream))})
                        break
                    if request.get('type') != 'audio':
                        raise ValueError('Expected audio or stop')
                    raw = base64.b64decode(request['pcm'], validate=True)
                    samples += len(raw) // 2
                    if samples > 16000 * 600:
                        raise ValueError('Recording limit is 10 minutes')
                    emit(self.wfile, {'type': 'text', 'text': model.feed(stream, raw), 'seconds': samples / 16000})
            except (OSError, EOFError, ValueError, KeyError, RuntimeError, AttributeError) as error:
                try:
                    emit(self.wfile, {'error': str(error)})
                except OSError:
                    pass
            finally:
                if stream:
                    model.stream_free(stream)
                lock.release()

    class Server(socketserver.ThreadingUnixStreamServer):
        daemon_threads = True

    path = socket_path()
    # systemd owns process lifetime; refuse to replace a live listener.
    if os.path.exists(path):
        with socket.socket(socket.AF_UNIX) as probe:
            try:
                probe.connect(path)
            except ConnectionRefusedError:
                os.unlink(path)
            else:
                raise RuntimeError('Service is already running')
    os.umask(0o077)
    with Server(path, Handler) as server:
        print('Model loaded; ready at ' + path, flush=True)
        server.serve_forever()


def relay(_args):
    with socket.socket(socket.AF_UNIX) as connection, selectors.DefaultSelector() as poll:
        connection.connect(socket_path())
        poll.register(sys.stdin.buffer, selectors.EVENT_READ)
        poll.register(connection, selectors.EVENT_READ)
        while True:
            for key, _ in poll.select():
                if key.fileobj is connection:
                    data = connection.recv(65536)
                    if not data:
                        return
                    sys.stdout.buffer.write(data)
                    sys.stdout.buffer.flush()
                else:
                    data = os.read(sys.stdin.fileno(), 65536)
                    if not data:
                        connection.shutdown(socket.SHUT_WR)
                        poll.unregister(sys.stdin.buffer)
                    else:
                        connection.sendall(data)


def ssh_command(host):
    return ['ssh', '-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
            '-o', 'ServerAliveInterval=10', '-o', 'ServerAliveCountMax=3', host,
            'exec "$HOME/.local/share/parakeet-voice/voice" relay']


def clean_text(text):
    # Nemotron auto-language output includes locale markers between utterances.
    text = re.sub(r'<[a-z]{2,3}-[A-Z]{2}>', '', text)
    # Never let recognition output inject terminal controls or a shell newline.
    return ' '.join(''.join(c for c in text if c.isprintable() or c.isspace()).split())


class Recording:
    def __init__(self, args):
        self.args = args
        self.events = queue.Queue()
        self.stop = threading.Event()
        self.paused = threading.Event()
        self.cancel = threading.Event()
        self.lifecycle_lock = threading.Lock()
        self.level = 0.0
        self.captured = 0.0
        self.processed = 0.0
        self.mic = None
        self.ssh = None
        # Bounded buffer: fail explicitly if inference cannot keep up.
        self.audio = queue.Queue(maxsize=300)

    def request_stop(self):
        self.stop.set()
        if self.mic and self.mic.poll() is None:
            self.mic.terminate()

    def toggle_pause(self):
        if self.paused.is_set():
            self.paused.clear()
        else:
            self.paused.set()
            self.level = 0.0

    def capture(self):
        try:
            while not self.cancel.is_set():
                raw = self.mic.stdout.read(BLOCK)
                if not raw:
                    if not self.stop.is_set():
                        raise RuntimeError('Microphone capture stopped unexpectedly')
                    break
                # Drain the capture pipe while paused: none of this audio is
                # buffered, transcribed, or replayed when recording resumes.
                if self.paused.is_set():
                    continue
                values = struct.unpack('<' + 'h' * (len(raw) // 2), raw)
                self.level = math.sqrt(sum(x*x for x in values) / len(values)) / 32768
                self.captured += len(values) / 16000
                self.audio.put_nowait(raw)
                if self.captured >= 600:
                    self.request_stop()
            self.audio.put(None, timeout=5)
        except (OSError, ValueError, queue.Full, struct.error) as error:
            self.events.put({'error': str(error) or 'Transcription cannot keep up; recording buffer is full'})
            self.cancel.set()
            self.request_stop()

    def run(self):
        try:
            with tempfile.TemporaryFile() as errors:
                with self.lifecycle_lock:
                    if self.cancel.is_set():
                        return
                    self.ssh = subprocess.Popen(ssh_command(self.args.host), stdin=subprocess.PIPE,
                                                stdout=subprocess.PIPE, stderr=errors)
                emit(self.ssh.stdin, {'type': 'start', 'lang': self.args.lang})
                try:
                    ready = read_message(self.ssh.stdout)
                except EOFError:
                    self.ssh.wait(timeout=15)
                    errors.seek(0)
                    raise RuntimeError(errors.read().decode(errors='replace').strip() or 'Service disconnected')
                if 'error' in ready:
                    raise RuntimeError(ready['error'])
                if ready.get('type') != 'ready':
                    raise RuntimeError('Invalid response from voice service')
                with self.lifecycle_lock:
                    if self.stop.is_set() or self.cancel.is_set():
                        return
                    command = ['parecord', '--raw', '--format=s16le', '--rate=16000', '--channels=1',
                               '--latency-msec=50', '--client-name=WezTerm voice']
                    if self.args.device:
                        command.append('--device=' + self.args.device)
                    self.mic = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=errors)
                self.events.put({'type': 'recording'})
                threading.Thread(target=self.capture, daemon=True).start()
                while not self.cancel.is_set():
                    try:
                        raw = self.audio.get(timeout=5)
                    except queue.Empty:
                        emit(self.ssh.stdin, {'type': 'ping'})
                        result = read_message(self.ssh.stdout)
                        if 'error' in result:
                            self.events.put(result)
                            return
                        continue
                    message = {'type': 'stop'} if raw is None else {
                        'type': 'audio', 'pcm': base64.b64encode(raw).decode()}
                    emit(self.ssh.stdin, message)
                    result = read_message(self.ssh.stdout)
                    self.events.put(result)
                    if 'error' in result or result.get('type') == 'done':
                        return
        except (OSError, ValueError, EOFError, RuntimeError, subprocess.SubprocessError) as error:
            self.events.put({'error': str(error)})
        finally:
            self.close()

    def close(self):
        with self.lifecycle_lock:
            self.cancel.set()
            self.request_stop()
            for process in (self.mic, self.ssh):
                if process and process.poll() is None:
                    try:
                        process.terminate()
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    except ProcessLookupError:
                        pass


def record(args):
    if not shutil.which('parecord'):
        raise RuntimeError('parecord is required on the microphone host (PulseAudio / PipeWire Pulse)')
    recording = Recording(args)

    def ui(screen):
        curses.curs_set(0)
        curses.mousemask(curses.ALL_MOUSE_EVENTS)
        screen.timeout(50)
        transcript, state, error = '', 'Connecting', ''
        send_pending = False
        threading.Thread(target=recording.run, daemon=True).start()
        while True:
            while not recording.events.empty():
                event = recording.events.get_nowait()
                if 'error' in event:
                    error, state = event['error'], 'Error'
                    send_pending = False
                elif event.get('type') == 'recording':
                    state = 'Recording'
                elif event.get('type') in ('text', 'done'):
                    transcript += event.get('text', '')
                    recording.processed = event.get('seconds', recording.processed)
                    if event['type'] == 'done':
                        state = 'Review'
            if send_pending and state == 'Review':
                send_pending = False
                if not clean_text(transcript):
                    error = 'No speech recognized'
                else:
                    try:
                        subprocess.run(['wezterm', 'cli', 'send-text', '--pane-id', str(args.pane_id)],
                                       input=clean_text(transcript), text=True, capture_output=True,
                                       timeout=10, check=True)
                        return
                    except (OSError, subprocess.SubprocessError) as failure:
                        error = getattr(failure, 'stderr', None) or str(failure)
            screen.erase()
            height, width = screen.getmaxyx()

            def put(y, x, value, attr=0):
                if y < 0 or y >= height or x >= width - 1:
                    return
                try:
                    screen.addnstr(y, x, value, max(0, width - x - 1), attr)
                except curses.error:
                    pass

            pause_label = '[Space:Resume]' if state == 'Paused' else '[Space:Pause]'
            buttons = [(0, pause_label, 'pause'), (15, '[Enter:Send]', 'send'), (28, '[Esc]', 'cancel')]
            for x, label, _ in buttons:
                put(0, x, label, curses.A_REVERSE)
            status = f'{state} {recording.captured:.1f}s'
            put(0, 34, status, curses.A_BOLD)
            meter_x = 35 + len(status)
            meter_width = max(0, min(20, width - meter_x - 3))
            if meter_width:
                db = 20 * math.log10(max(recording.level, 0.000001))
                bars = int(max(0, min(1, (db + 60) / 60)) * meter_width) if state == 'Recording' else 0
                put(0, meter_x, '[' + '#' * bars + '.' * (meter_width - bars) + ']')
            text = clean_text(transcript) or ('Listening...' if state == 'Recording' else '')
            if error:
                text = 'Error: ' + clean_text(error)
            available = max(0, width - 1)
            if len(text) > available:
                text = '...' + text[-(available - 3):] if available > 3 else '.' * available
            put(1, 0, text, curses.A_BOLD if error else 0)
            screen.refresh()
            key = screen.getch()
            action = {32: 'pause', 10: 'send', 13: 'send', 27: 'cancel', 3: 'cancel'}.get(key)
            if key == curses.KEY_MOUSE:
                try:
                    _, x, y, _, flags = curses.getmouse()
                    if y == 0 and flags & (curses.BUTTON1_CLICKED | curses.BUTTON1_RELEASED):
                        action = next((name for left, label, name in buttons if left <= x < left + len(label)), None)
                except curses.error:
                    pass
            if action == 'cancel':
                return
            if action == 'pause' and state in ('Recording', 'Paused'):
                recording.toggle_pause()
                state = 'Paused' if recording.paused.is_set() else 'Recording'
            if action == 'send' and state in ('Recording', 'Paused', 'Review'):
                send_pending = True
                if state != 'Review':
                    recording.request_stop()
                    state = 'Finishing'

    try:
        print('\033]0;Voice input\007', end='', flush=True)
        curses.wrapper(ui)
    finally:
        recording.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest='mode', required=True)
    service = modes.add_parser('serve')
    service.add_argument('--library', required=True)
    service.add_argument('--model', required=True)
    modes.add_parser('relay')
    client = modes.add_parser('record')
    client.add_argument('--host', default='ampere')
    client.add_argument('--lang', default='en-US')
    client.add_argument('--pane-id', required=True, type=int)
    client.add_argument('--device', default=os.environ.get('PARAKEET_MIC'))
    args = parser.parse_args()
    try:
        {'serve': serve, 'relay': relay, 'record': record}[args.mode](args)
    except (OSError, RuntimeError, KeyboardInterrupt) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
