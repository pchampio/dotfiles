/**
 * Minimal neovim msgpack-RPC client over stdio.
 * Spawns `nvim --embed`, sends requests/notifications, dispatches responses.
 */

import { spawn, type ChildProcess } from "node:child_process";
import { encode, decode, DecodeError } from "./msgpack.js";

type Pending = { resolve: (v: unknown) => void; reject: (e: Error) => void };

export class NvimClient {
  private proc: ChildProcess | null = null;
  private nextId = 0;
  private pending = new Map<number, Pending>();
  private buf = Buffer.alloc(0);
  private dead = false;

  /** Spawn nvim --embed and wire up stdio. */
  async start(binary = "nvim", extraArgs: string[] = []): Promise<void> {
    this.proc = spawn(binary, ["--embed", ...extraArgs], {
      stdio: ["pipe", "pipe", "ignore"],
    });

    this.proc.stdout!.on("data", (chunk: Buffer) => {
      this.buf = Buffer.concat([this.buf, chunk]);
      this.drain();
    });

    this.proc.on("error", (err) => this.rejectAll(err));
    this.proc.on("exit", () => {
      this.dead = true;
      this.rejectAll(new Error("nvim exited"));
    });
  }

  /** Send an RPC request and wait for the response (with timeout). */
  request(method: string, args: unknown[] = [], timeoutMs = 2000): Promise<unknown> {
    if (this.dead) return Promise.reject(new Error("nvim is dead"));
    return new Promise<unknown>((resolve, reject) => {
      const id = this.nextId++;
      const timer = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`nvim request timeout: ${method}`));
        }
      }, timeoutMs);
      this.pending.set(id, {
        resolve: (v) => { clearTimeout(timer); resolve(v); },
        reject: (e) => { clearTimeout(timer); reject(e); },
      });
      this.write(encode([0, id, method, args]));
    });
  }

  /** Send an RPC notification (fire-and-forget). */
  notify(method: string, args: unknown[] = []): void {
    if (this.dead) return;
    this.write(encode([2, method, args]));
  }

  /** Register a handler for incoming notifications. */
  private notifHandlers = new Map<string, (args: unknown[]) => void>();
  onNotification(method: string, handler: (args: unknown[]) => void): void {
    this.notifHandlers.set(method, handler);
  }

  close(): void {
    this.dead = true;
    try { this.proc?.kill(); } catch {}
    this.proc = null;
    this.rejectAll(new Error("closed"));
  }

  // ── internals ────────────────────────────────────────────────────────

  private write(data: Buffer): void {
    try { this.proc?.stdin?.write(data); } catch {}
  }

  private drain(): void {
    while (this.buf.length > 0) {
      try {
        const { value, offset } = decode(this.buf);
        this.buf = this.buf.subarray(offset);
        this.dispatch(value as unknown[]);
      } catch (e) {
        if (e instanceof DecodeError) break; // incomplete, wait for more
        throw e;
      }
    }
  }

  private dispatch(msg: unknown[]): void {
    const type = msg[0] as number;
    if (type === 1) {
      // Response: [1, msgid, error, result]
      const id = msg[1] as number;
      const p = this.pending.get(id);
      if (!p) return;
      this.pending.delete(id);
      if (msg[2] !== null && msg[2] !== undefined) {
        const errMsg = Array.isArray(msg[2]) ? String(msg[2][1] ?? msg[2]) : String(msg[2]);
        p.reject(new Error(errMsg));
      } else {
        p.resolve(msg[3]);
      }
    } else if (type === 2) {
      // Notification: [2, method, params]
      const method = msg[1] as string;
      const handler = this.notifHandlers.get(method);
      handler?.(msg[2] as unknown[]);
    }
    // type 0 = incoming request from nvim (rare, ignore)
  }

  private rejectAll(err: Error): void {
    for (const [, p] of this.pending) p.reject(err);
    this.pending.clear();
  }
}
