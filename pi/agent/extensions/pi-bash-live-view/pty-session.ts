import * as fs from 'node:fs';
import pty from 'node-pty';
import { createTerminalEmulator } from './terminal-emulator.ts';
import { killPtyProcess } from './pty-kill.ts';

const isBun = !!(globalThis as any).Bun;

const DEBUG_LOG = '/tmp/live-term.log';
function dbg(...args: any[]) {
  try {
    const line = `[${new Date().toISOString()}] ${args.map(a => typeof a === 'string' ? a : JSON.stringify(a)).join(' ')}\n`;
    fs.appendFileSync(DEBUG_LOG, line);
  } catch { /* ignore */ }
}

/**
 * Bun's tty.ReadStream calls lseek before read on PTY fds, producing ESPIPE
 * on every read — no data events are ever emitted.
 *
 * We work around this by:
 * 1. Pausing the broken tty.ReadStream (not destroyed, so the fd stays open
 *    for node-pty's native exit detection).
 * 2. Reading from the fd using fs.read() with position=null (which skips
 *    lseek) in an async loop, and forwarding data through the original
 *    socket's emit so node-pty's onData/close lifecycle still works.
 */
function patchPtySocketForBun(ptyProcess: pty.IPty): void {
  dbg('patchPtySocketForBun called, isBun:', isBun);
  if (!isBun) return;

  const proc = ptyProcess as any;
  const oldSocket = proc._socket;
  dbg('oldSocket exists:', !!oldSocket, 'type:', oldSocket?.constructor?.name);
  if (!oldSocket) return;

  const fd: number = proc._fd ?? proc.fd;
  dbg('PTY fd:', fd);
  if (fd == null) return;

  // Capture origEmit first — needed by both destroy patch and emit patch.
  const origEmit = oldSocket.emit;
  let readLoopDone = false;

  // Prevent Bun's ReadStream from closing the fd when it self-destructs
  // after ESPIPE. We need the fd open for our readLoop and node-pty's
  // native exit detection.
  oldSocket.destroy = function patchedDestroy(this: any) {
    dbg('oldSocket.destroy() intercepted — suppressing fd close');
    this.destroyed = true;
    this.readable = false;
    return this;
  };
  oldSocket.pause();
  try { oldSocket.unref(); } catch { /* ignore */ }

  // Swallow ESPIPE errors AND premature close from the broken tty.ReadStream.
  oldSocket.emit = function patchedEmit(this: any, event: string, ...args: any[]) {
    if (event === 'error') {
      dbg('oldSocket error event:', args[0]?.code, args[0]?.message);
      if (args[0]?.code === 'ESPIPE') return false;
    }
    if (event === 'close' && !readLoopDone) {
      dbg('oldSocket close event BLOCKED (readLoop still active)');
      return false;
    }
    return origEmit.apply(this, [event, ...args]);
  };

  // Read from the PTY fd using fs.read with position=null to avoid lseek.
  const buf = Buffer.alloc(16384);
  let stopped = false;
  let readCount = 0;

  dbg('starting readLoop on fd:', fd);

  function readLoop() {
    if (stopped) return;
    readCount++;
    if (readCount <= 5) dbg('readLoop iteration', readCount);
    fs.read(fd, buf, 0, buf.length, null, (err, bytesRead) => {
      if (stopped) return;
      if (err) {
        dbg('fs.read error:', (err as any).code, (err as any).message, (err as any).syscall, (err as any).errno);
        if ((err as any).code === 'EAGAIN') {
          setTimeout(readLoop, 10);
          return;
        }
        if ((err as any).code === 'EIO' || (err as any).code === 'ESPIPE') {
          stopped = true;
          readLoopDone = true;
          dbg('stopping readLoop due to', (err as any).code);
          origEmit.call(oldSocket, 'close');
          return;
        }
        stopped = true;
        readLoopDone = true;
        dbg('stopping readLoop due to unexpected error:', (err as any).code);
        origEmit.call(oldSocket, 'error', err);
        return;
      }
      if (bytesRead === 0) {
        stopped = true;
        readLoopDone = true;
        dbg('readLoop: bytesRead=0, emitting close');
        origEmit.call(oldSocket, 'close');
        return;
      }
      const text = buf.toString('utf8', 0, bytesRead);
      dbg('readLoop: got', bytesRead, 'bytes:', JSON.stringify(text.slice(0, 200)));
      origEmit.call(oldSocket, 'data', text);
      readLoop();
    });
  }

  readLoop();

  // Allow stopping the loop from dispose.
  proc._bunStopRead = () => { stopped = true; dbg('bunStopRead called'); };
}

export type PtyTerminalSessionOptions = {
  command: string;
  cwd: string;
  cols: number;
  rows: number;
  scrollback: number;
  shell: string;
  shellArgs?: string[];
  env?: Record<string, string | undefined>;
};

type TerminalEmulator = ReturnType<typeof createTerminalEmulator>;

type ExitListener = (exitCode: number | null, signal?: number) => void;

export class PtyTerminalSession {
  private readonly ptyProcess: pty.IPty;
  private readonly terminalEmulator: TerminalEmulator;
  private readonly startedAt = Date.now();
  private readonly exitListeners = new Set<ExitListener>();
  private _exited = false;
  private _exitCode: number | null = null;
  private _signal: number | undefined;
  private disposed = false;

  constructor(options: PtyTerminalSessionOptions) {
    const {
      command,
      cwd,
      cols,
      rows,
      scrollback,
      shell,
      shellArgs = [],
      env,
    } = options;

    this.terminalEmulator = createTerminalEmulator({ cols, rows, scrollback });
    this.ptyProcess = pty.spawn(shell, [...shellArgs, command], {
      name: 'xterm-256color',
      cols,
      rows,
      cwd,
      env: {
        ...process.env,
        ...env,
        TERM: 'xterm-256color',
        COLORTERM: 'truecolor',
      },
    });

    patchPtySocketForBun(this.ptyProcess);

    this.ptyProcess.onData((chunk) => {
      void this.terminalEmulator.consumeProcessStdout(chunk, {
        elapsedMs: Date.now() - this.startedAt,
      });
    });

    this.ptyProcess.onExit(({ exitCode, signal }) => {
      this._exited = true;
      this._exitCode = exitCode;
      this._signal = signal;
      void this.whenIdle().then(() => {
        for (const listener of [...this.exitListeners]) {
          listener(exitCode, signal);
        }
      });
    });
  }

  get exited() {
    return this._exited;
  }

  get exitCode() {
    return this._exitCode;
  }

  get signal() {
    return this._signal;
  }

  get pid() {
    return this.ptyProcess.pid;
  }

  get cols() {
    return this.terminalEmulator.cols;
  }

  get rows() {
    return this.terminalEmulator.rows;
  }

  addExitListener(listener: ExitListener): () => void {
    this.exitListeners.add(listener);
    if (this._exited) {
      void this.whenIdle().then(() => {
        if (this.exitListeners.has(listener)) {
          listener(this._exitCode, this._signal);
        }
      });
    }
    return () => {
      this.exitListeners.delete(listener);
    };
  }

  whenIdle(): Promise<void> {
    return this.terminalEmulator.whenIdle();
  }

  getViewportSnapshot() {
    return this.terminalEmulator.getViewportSnapshot();
  }

  getStrippedTextIncludingEntireScrollback() {
    return this.terminalEmulator.getStrippedTextIncludingEntireScrollback();
  }

  subscribe(listener: (payload: { elapsedMs: number; snapshot: ReturnType<TerminalEmulator['getViewportSnapshot']>; inAltScreen: boolean; inSyncRender: boolean }) => void): () => void {
    return this.terminalEmulator.subscribe(listener);
  }

  kill(signal = 'SIGTERM') {
    if (this._exited) return;
    killPtyProcess(this.ptyProcess, signal);
  }

  dispose() {
    if (this.disposed) return;
    this.disposed = true;
    // Stop the Bun read loop if active.
    (this.ptyProcess as any)._bunStopRead?.();
    this.kill();
    this.terminalEmulator.dispose();
    this.exitListeners.clear();
  }
}
