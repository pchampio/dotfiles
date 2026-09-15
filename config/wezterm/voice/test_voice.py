"""Protocol/lifecycle tests; real-model smoke test is documented in README.md."""
import argparse
import base64
import io
import multiprocessing
import os
from pathlib import Path
import socket
import tempfile
import time
import unittest
from unittest.mock import patch, MagicMock

import voice


class FakeModel:
    ctx = 1

    def __init__(self, *_):
        pass

    def checked(self, pointer):
        return pointer

    def stream_begin_lang(self, ctx, lang):
        if lang == b'invalid':
            raise RuntimeError('Unknown language')
        return 1

    def feed(self, stream, raw):
        return 'Hello'

    def result(self, text):
        return text

    def stream_finalize_json(self, stream):
        return ' world.'

    def stream_free(self, stream):
        pass


def fake_server(directory):
    os.environ['XDG_RUNTIME_DIR'] = directory
    voice.Model = FakeModel
    voice.serve(argparse.Namespace(library='', model=''))


class ProtocolTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = str(Path(self.directory.name) / 'parakeet-voice.sock')
        self.server = multiprocessing.Process(target=fake_server, args=(self.directory.name,))
        self.server.start()
        for _ in range(100):
            if os.path.exists(self.path):
                break
            time.sleep(.01)
        self.connections = []

    def tearDown(self):
        for connection, stream in self.connections:
            stream.close()
            connection.close()
        self.server.terminate()
        self.server.join(3)
        self.directory.cleanup()

    def connect(self):
        connection = socket.socket(socket.AF_UNIX)
        connection.settimeout(2)
        connection.connect(self.path)
        stream = connection.makefile('rwb')
        self.connections.append((connection, stream))
        return stream

    def start(self, stream, lang='auto'):
        voice.emit(stream, {'type': 'start', 'lang': lang})
        return voice.read_message(stream)

    def test_incremental_text_and_final_tail(self):
        stream = self.connect()
        self.assertEqual(self.start(stream), {'type': 'ready'})
        voice.emit(stream, {'type': 'audio', 'pcm': base64.b64encode(b'\0\0'*1600).decode()})
        partial = voice.read_message(stream)
        self.assertEqual(partial['seconds'], .1)
        voice.emit(stream, {'type': 'stop'})
        final = voice.read_message(stream)
        self.assertEqual(final['type'], 'done')
        self.assertEqual(partial['text'] + final['text'], 'Hello world.')

    def test_busy_session_is_rejected(self):
        self.start(self.connect())
        self.assertIn('Another recording', voice.read_message(self.connect())['error'])

    def test_bad_audio_ends_session_and_model_is_reusable(self):
        stream = self.connect()
        self.start(stream)
        voice.emit(stream, {'type': 'audio', 'pcm': '%%%bad base64'})
        self.assertIn('error', voice.read_message(stream))
        time.sleep(.03)
        self.assertEqual(self.start(self.connect()), {'type': 'ready'})

    def test_invalid_language_returns_error(self):
        self.assertIn('Unknown language', self.start(self.connect(), 'invalid')['error'])

    def test_paused_session_keepalive(self):
        stream = self.connect()
        self.start(stream)
        voice.emit(stream, {'type': 'ping'})
        self.assertEqual(voice.read_message(stream), {'type': 'pong'})
        voice.emit(stream, {'type': 'stop'})
        self.assertEqual(voice.read_message(stream)['type'], 'done')


class InputTest(unittest.TestCase):
    def test_invalid_protocol_and_limits(self):
        for data in (b'[]\n', b'{}', b'x' * (voice.MAX_LINE + 1)):
            with self.assertRaises(ValueError):
                voice.read_message(io.BytesIO(data))

    def test_transcript_cannot_include_enter_or_escape(self):
        self.assertEqual(voice.clean_text('  café\nhello\rworld\x1b\x00 '), 'café hello world')

    def test_language_markers_are_not_pasted(self):
        self.assertEqual(voice.clean_text('Hello. <en-US> Bonjour. <fr-FR>'), 'Hello. Bonjour.')

    def test_pcm_input_validation(self):
        for raw in (b'', b'1', b'\0' * 32002):
            with self.assertRaises(ValueError):
                voice.Model.feed(None, None, raw)

    def test_cancel_terminates_capture(self):
        recording = voice.Recording(argparse.Namespace())
        with patch('voice.subprocess.Popen') as process:
            recording.mic = process.return_value
            recording.mic.poll.return_value = None
            recording.close()
            recording.mic.terminate.assert_called()
            self.assertTrue(recording.cancel.is_set())

    def test_paused_audio_is_discarded_and_resume_keeps_session(self):
        recording = voice.Recording(argparse.Namespace())
        recording.mic = MagicMock()
        recording.toggle_pause()

        def resume():
            recording.toggle_pause()
            return b'\0\0' * 1600

        def finish():
            recording.stop.set()
            return b''

        reads = iter([lambda: b'\1\0' * 1600, resume, finish])
        recording.mic.stdout.read.side_effect = lambda _: next(reads)()
        recording.capture()
        self.assertAlmostEqual(recording.captured, .1)
        self.assertEqual(recording.audio.get_nowait(), b'\0\0' * 1600)
        self.assertIsNone(recording.audio.get_nowait())
        self.assertTrue(recording.audio.empty())

    def test_enter_finishes_and_sends_from_recording_or_paused(self):
        for keys in ([10], [32, 10], [32, 32, 10]):
            with self.subTest(keys=keys):
                recording = voice.Recording(argparse.Namespace())
                recording.events.put({'type': 'recording'})
                recording.events.put({'type': 'text', 'text': 'Hello'})
                recording.request_stop = lambda: recording.events.put({'type': 'done', 'text': ' world.'})
                screen = MagicMock()
                screen.getmaxyx.return_value = (2, 90)
                screen.getch.side_effect = keys
                args = argparse.Namespace(host='ampere', lang='auto', pane_id=123)
                with patch('voice.Recording', return_value=recording), \
                     patch('voice.threading.Thread'), patch('voice.shutil.which', return_value='/bin/parecord'), \
                     patch('voice.curses.wrapper', side_effect=lambda ui: ui(screen)), \
                     patch('voice.curses.curs_set'), patch('voice.curses.mousemask'), \
                     patch('voice.subprocess.run') as send, patch('builtins.print'):
                    voice.record(args)
                send.assert_called_once()
                self.assertEqual(send.call_args.args[0][-2:], ['--pane-id', '123'])
                self.assertEqual(send.call_args.kwargs['input'], 'Hello world.')


if __name__ == '__main__':
    unittest.main()
