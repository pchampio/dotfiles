#!/usr/bin/env python3
"""tunnel-on-demand: own localhost ports and open `ssh -L` on first use.

Each configured port listens on 127.0.0.1:<listen>. One ssh master connection
is kept per host (ControlMaster), started on the first connection, inside a
pty: if it needs a password / passphrase / host key confirmation, browsers get
a "connecting..." page with a small built-in terminal to log in (no external assets). Each port's forward is
then added to the master (`ssh -O forward`) towards a unix socket, and
connections are spliced (raw TCP) to it, so websockets / keep-alive just work.

Config: ~/.config/tunnel-on-demand/config.toml (see config.example.toml).
"""

import asyncio
import fcntl
import hashlib
import json
import logging
import os
import re
import resource
import signal
import struct
import sys
import termios
import time
import tomllib
from pathlib import Path

CONFIG = Path(os.environ.get("TOD_CONFIG", Path.home() / ".config/tunnel-on-demand/config.toml"))
RUNDIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "tunnel-on-demand"
PREFIX = "/__tunnel__/"
HTTP_METHODS = {b"GET", b"POST", b"PUT", b"DELETE", b"HEAD", b"OPTIONS", b"PATCH", b"CONNECT", b"TRACE"}
RESPAWN_BACKOFF = 3.0
SSH_COMMS = {"ssh", "tssh"}
RECLAIM_INTERVAL = 30
OUTPUT_CAP = 256 * 1024
TERM_SIZE = (14, 100)  # rows, cols of the login terminal pty
PROMPT_RE = re.compile(rb"(?i)(password|passphrase|verification|code|yes/no|pin|otp)[^\n]*[:?]\s*$")
ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|\r")
LOCAL_HOSTS = re.compile(r"^(localhost|127\.\d+\.\d+\.\d+|\[::1\])(:\d+)?$")

log = logging.getLogger("tunnel-on-demand")


class Host:
    """One ssh master connection (run in a pty) shared by all ports of a host."""

    def __init__(self, cfg):
        self.host = cfg["host"]
        self.identity_file = cfg.get("identity_file")
        self.ssh_args = [os.path.expanduser(a) for a in cfg.get("ssh_args", [])]
        self.ssh_auth_sock = cfg.get("ssh_auth_sock")
        self.agent_used = None
        self.idle_timeout = float(cfg.get("idle_timeout", 0))
        key = json.dumps([self.host, self.identity_file, self.ssh_args, self.ssh_auth_sock])
        self.ctl = RUNDIR / f"{hashlib.sha1(key.encode()).hexdigest()[:12]}.ctl"
        self.tunnels = []
        self.proc = None
        self.fd = None
        self.gen = 0  # incremented on each master spawn: forwards belong to one master
        self.state = "idle"  # idle | connecting | up | error
        self.started = 0.0
        self.last_spawn = 0.0
        self.stopping = False
        self.out = bytearray()
        self.out_base = 0  # absolute offset of out[0]
        self.changed = asyncio.Event()
        self.ready = asyncio.Event()
        self.lock = asyncio.Lock()

    def running(self):
        return self.proc is not None and self.proc.returncode is None

    async def ensure(self, force=False):
        async with self.lock:
            if self.running() and self.state == "connecting" and self.agent_used != agent_socket(self.ssh_auth_sock):
                # Stuck at a login prompt but the configured agent (re)appeared: retry with it.
                log.info("[%s] agent changed, reconnecting", self.host)
                self.stop()
                await self.proc.wait()
                force = True
            if self.running():
                return
            if not force and time.monotonic() - self.last_spawn < RESPAWN_BACKOFF:
                return
            await self._spawn()

    async def _spawn(self):
        RUNDIR.mkdir(mode=0o700, parents=True, exist_ok=True)
        self.ctl.unlink(missing_ok=True)
        self.ready.clear()
        self.gen += 1
        self.state = "connecting"
        self.stopping = False
        self.started = self.last_spawn = time.monotonic()
        cmd = [
            "ssh", "-N", "-M",
            "-S", str(self.ctl),
            "-o", "ControlPersist=no",
            "-o", "StreamLocalBindUnlink=yes",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=5",
            "-o", "ServerAliveCountMax=3",
        ]
        if self.identity_file:
            cmd += ["-i", os.path.expanduser(self.identity_file), "-o", "IdentitiesOnly=yes"]
        cmd += [*self.ssh_args, self.host]
        env = {**os.environ, "TERM": "dumb", "SSH_ASKPASS_REQUIRE": "never"}
        if sock := agent_socket(self.ssh_auth_sock):
            env["SSH_AUTH_SOCK"] = sock
        self.agent_used = sock
        log.info("[%s] spawning master (agent %s): %s", self.host, env.get("SSH_AUTH_SOCK"), " ".join(cmd))
        # The terminal shows the current attempt only (offsets stay absolute for streaming pages).
        self.out_base += len(self.out)
        self.out.clear()
        self._append(f"\x1b[2m$ ssh {self.host}\x1b[0m\r\n".encode())

        master, slave = os.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", *TERM_SIZE, 0, 0))
        try:
            self.proc = await asyncio.create_subprocess_exec(
                *cmd, stdin=slave, stdout=slave, stderr=slave, env=env, preexec_fn=_controlling_tty,
            )
        except OSError as e:
            os.close(master)
            self.state = "error"
            self._append(f"failed to start ssh: {e}\r\n".encode())
            return
        finally:
            os.close(slave)
        os.set_blocking(master, False)
        self.fd = master
        asyncio.get_running_loop().add_reader(master, self._on_output, master)
        asyncio.create_task(self._watch(self.proc, master))

    def _on_output(self, fd):
        try:
            data = os.read(fd, 65536)
        except BlockingIOError:
            return
        except OSError:  # EIO: the ssh side of the pty is closed
            data = b""
        if not data:
            asyncio.get_running_loop().remove_reader(fd)
            return
        self._append(data)

    def _append(self, data):
        self.out += data
        if len(self.out) > OUTPUT_CAP:
            drop = len(self.out) - OUTPUT_CAP
            del self.out[:drop]
            self.out_base += drop
        self.changed.set()
        self.changed = asyncio.Event()

    async def _watch(self, proc, fd):
        async def probe():
            while proc.returncode is None:
                if self.ctl.exists() and (await self.mux("check"))[0] == 0:
                    self.state = "up"
                    self.ready.set()
                    log.info("[%s] master up after %.1fs", self.host, time.monotonic() - self.started)
                    return
                await asyncio.sleep(0.3)

        prober = asyncio.create_task(probe())
        code = await proc.wait()
        prober.cancel()
        await asyncio.sleep(0.1)  # let the last output be read
        self._on_output(fd)
        asyncio.get_running_loop().remove_reader(fd)
        os.close(fd)
        if self.fd == fd:
            self.fd = None
        if proc is self.proc:
            self.ready.clear()
            self.state = "idle" if self.stopping else "error"
        self._append(f"\x1b[2m[ssh exited with code {code}]\x1b[0m\r\n".encode())
        log.info("[%s] master exited (%s)", self.host, code)

    async def mux(self, op, *args):
        """Talk to the running master: ssh -S ctl -O <op> ..."""
        p = await asyncio.create_subprocess_exec(
            "ssh", "-S", str(self.ctl), "-O", op, *args, self.host,
            stdin=asyncio.subprocess.DEVNULL, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT,
        )
        try:
            out, _ = await asyncio.wait_for(p.communicate(), 10)
        except asyncio.TimeoutError:
            p.kill()
            return 1, "ssh -O timed out"
        return p.returncode, out.decode(errors="replace").strip()

    async def heal(self):
        """After a failed request: drop the master if it no longer answers."""
        if self.running() and self.state == "up" and (await self.mux("check"))[0] != 0:
            log.warning("[%s] master not answering, killing it", self.host)
            self.stopping = False
            self.proc.kill()

    def write(self, data):
        if self.fd is not None and self.running():
            os.write(self.fd, data)

    def stop(self):
        if self.running():
            self.stopping = True
            self.proc.terminate()

    def prompting(self):
        return self.state == "connecting" and bool(PROMPT_RE.search(self.out[-300:]))

    def tail(self, n=8):
        text = ANSI_RE.sub("", self.out[-4000:].decode(errors="replace"))
        return [line for line in text.split("\n") if line.strip()][-n:]

    async def reap_idle(self):
        if self.idle_timeout <= 0:
            return
        while True:
            await asyncio.sleep(min(10, self.idle_timeout))
            idle = time.monotonic() - max(t.last_used for t in self.tunnels)
            if self.running() and not any(t.active for t in self.tunnels) and idle > self.idle_timeout:
                log.info("[%s] idle for %ds, closing ssh", self.host, self.idle_timeout)
                self.stop()


class Tunnel:
    """One local port, forwarded through its host's master to a unix socket."""

    def __init__(self, cfg, host):
        self.host = host
        self.listen = int(cfg["listen"])
        self.bind = cfg.get("bind", "127.0.0.1")
        # "addr" alone forwards to the same port as listen (needed for ranges).
        remote = str(cfg.get("remote", "localhost"))
        self.remote = remote if ":" in remote else f"{remote}:{self.listen}"
        self.quiet = bool(cfg.get("_range"))  # don't log each port of a range
        self.sock = RUNDIR / f"{self.listen}.sock"
        self.fwd_gen = 0  # master generation this port is forwarded on
        self.fwd_error = ""
        self.lock = asyncio.Lock()
        self.active = 0
        self.last_used = time.monotonic()

    @property
    def name(self):
        return f"{self.bind}:{self.listen} -> {self.host.host} {self.remote}"

    @property
    def target(self):
        """Where the remote end is, in words: "ampere:8701", or "db:5432 (via ampere)"."""
        rhost, _, rport = self.remote.rpartition(":")
        if rhost in ("0.0.0.0", "localhost", "127.0.0.1", "::1", "[::1]"):
            return f"{self.host.host}:{rport}"
        return f"{rhost}:{rport} (via {self.host.host})"

    @property
    def state(self):
        if self.host.state != "up":
            return self.host.state
        if self.fwd_gen == self.host.gen:
            return "up"
        return "error" if self.fwd_error else "connecting"

    async def ensure_forward(self, recreate=False):
        async with self.lock:
            if self.host.state != "up":
                return False
            if self.fwd_gen == self.host.gen and not recreate:
                return True
            if recreate:  # the master still has it registered: re-adding alone would be a no-op
                await self.host.mux("cancel", "-L", f"{self.sock}:{self.remote}")
            self.sock.unlink(missing_ok=True)
            code, out = await self.host.mux("forward", "-L", f"{self.sock}:{self.remote}")
            if code != 0:
                self.fwd_error = out or f"ssh -O forward failed ({code})"
                log.warning("[%d] forward failed: %s", self.listen, self.fwd_error)
                await self.host.heal()
                return False
            self.fwd_gen, self.fwd_error = self.host.gen, ""
            log.info("[%d] forwarded: %s", self.listen, self.name)
            return True

    async def wait_ready(self, timeout):
        await self.host.ensure()
        try:
            await asyncio.wait_for(self.host.ready.wait(), timeout)
        except asyncio.TimeoutError:
            return False
        return await self.ensure_forward()

    def status(self):
        h = self.host
        return {
            "state": self.state,
            "prompt": h.prompting(),
            "listen": self.listen,
            "host": h.host,
            "remote": self.remote,
            "target": self.target,
            "elapsed": round(time.monotonic() - h.started, 1) if h.started else 0,
            "log": self.fwd_error.splitlines() if self.fwd_error else h.tail(),
        }

    # ---------------------------------------------------------- listening
    async def open(self):
        """Listen on the port, or return None if something else already owns it."""
        try:
            server = await asyncio.start_server(self.handle, self.bind, self.listen, reuse_address=True)
        except OSError as e:
            log.info("[%d] skipped: cannot listen on %s:%d (%s)", self.listen, self.bind, self.listen, e.strerror)
            return None
        if not self.quiet:
            log.info("[%d] listening: %s", self.listen, self.name)
        return server

    async def handle(self, reader, writer):
        self.active += 1
        self.last_used = time.monotonic()
        try:
            await self._handle(reader, writer)
        except (ConnectionError, asyncio.TimeoutError, asyncio.IncompleteReadError):
            pass
        except Exception:
            log.exception("[%d] connection error", self.listen)
        finally:
            self.active -= 1
            self.last_used = time.monotonic()
            writer.close()

    async def _handle(self, reader, writer):
        buf = await read_head(reader)
        head = buf.split(b"\r\n\r\n", 1)[0]
        first = head.split(b"\r\n", 1)[0].split(b" ")
        is_http = len(first) >= 2 and first[0] in HTTP_METHODS
        path = first[1].decode(errors="replace") if is_http else ""

        if path.startswith(PREFIX):
            await self.api(path[len(PREFIX):], first[0], head, buf, reader, writer)
            return

        wants_html = is_http and b"text/html" in head.lower()
        # Browsers get the waiting page quickly; other clients just wait for the tunnel.
        if await self.wait_ready(2 if wants_html else 30):
            result = await self.splice(buf, reader, writer)
            if result == "nosock":  # forward vanished (socket removed, master restarted): re-add it once
                if await self.ensure_forward(recreate=True):
                    result = await self.splice(buf, reader, writer)
            if result == "ok":
                return
            await self.host.heal()
            reason = "remote"  # tunnel up but nothing answered at the remote end
        else:
            reason = "connecting"

        if wants_html:
            respond(writer, "503 Service Unavailable", "text/html; charset=utf-8", page(self, reason), "Retry-After: 2\r\n")
        elif is_http:
            s = self.status()
            if reason == "remote":
                msg = (f"tunnel-on-demand: nothing is running on {self.target}.\n"
                       f"The ssh tunnel is up, but no program listens on that port there: start it, then retry.\n")
                respond(writer, "503 Service Unavailable", "text/plain; charset=utf-8", msg.encode(), "Retry-After: 2\r\n")
                return
            msg = f"tunnel-on-demand: {self.name}: {s['state']}\n"
            if s["prompt"]:
                msg += f"ssh is waiting for a login: open http://localhost:{self.listen}/ in a browser\n"
            msg += "\n".join(s["log"]) + "\n"
            respond(writer, "503 Service Unavailable", "text/plain; charset=utf-8", msg.encode(), "Retry-After: 2\r\n")

    async def api(self, action, method, head, buf, reader, writer):
        action, _, query = action.partition("?")
        h = self.host
        if action == "status":
            if self.state != "up":
                await h.ensure()
                await self.ensure_forward()
            respond(writer, "200 OK", "application/json", json.dumps(self.status()).encode())
        elif action == "output":
            # Long poll on the terminal output, from absolute offset `from`.
            m = re.search(r"from=(\d+)", query)
            start = int(m.group(1)) if m else 0
            if start >= h.out_base + len(h.out):
                try:
                    await asyncio.wait_for(h.changed.wait(), 20)
                except asyncio.TimeoutError:
                    pass
            start = max(start, h.out_base)
            data = bytes(h.out[start - h.out_base:])
            respond(writer, "200 OK", "application/octet-stream", data, f"X-Offset: {start + len(data)}\r\n")
        elif action in ("input", "retry") and method == b"POST":
            # Keystrokes go to ssh: refuse cross-site requests (custom header => CORS
            # preflight we never answer) and DNS rebinding (Host must be local).
            host_hdr = re.search(rb"(?im)^host:\s*(\S+)", head)
            if not re.search(rb"(?im)^x-tunnel:", head) or not host_hdr or not LOCAL_HOSTS.match(host_hdr.group(1).decode()):
                respond(writer, "403 Forbidden", "text/plain", b"forbidden\n")
                return
            if action == "input":
                h.write(await read_body(head, buf, reader))
            else:
                if h.state != "up":
                    h.stop()
                    if h.proc:
                        await h.proc.wait()
                    await h.ensure(force=True)
                self.fwd_error = ""
                await self.ensure_forward()
            respond(writer, "200 OK", "application/json", json.dumps(self.status()).encode())
        else:
            respond(writer, "404 Not Found", "text/plain", b"not found\n")

    async def splice(self, buf, reader, writer):
        """Forward the connection through the ssh socket: "ok", "nosock" or "noanswer" (remote closed silently)."""
        try:
            br, bw = await asyncio.open_unix_connection(str(self.sock))
        except OSError:
            return "nosock"
        answered = False

        async def pipe(r, w, mark):
            nonlocal answered
            try:
                while data := await r.read(65536):
                    if mark:
                        answered = True
                    w.write(data)
                    await w.drain()
                if w.can_write_eof():
                    w.write_eof()
            except (ConnectionError, OSError):
                pass

        bw.write(buf)
        await bw.drain()
        up = asyncio.create_task(pipe(reader, bw, False))
        await pipe(br, writer, True)
        up.cancel()
        bw.close()
        return "ok" if answered else "noanswer"


def _controlling_tty():
    # Make the pty ssh's controlling terminal, so it prompts there (it reads /dev/tty).
    os.setsid()
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)


async def read_head(reader, limit=65536, timeout=10):
    buf = b""
    try:
        while b"\r\n\r\n" not in buf and len(buf) < limit:
            # Server-speaks-first protocols send nothing: don't wait for a head forever.
            chunk = await asyncio.wait_for(reader.read(limit), timeout if buf else 1)
            if not chunk:
                break
            buf += chunk
    except asyncio.TimeoutError:
        pass
    return buf


async def read_body(head, buf, reader, limit=65536):
    m = re.search(rb"(?im)^content-length:\s*(\d+)", head)
    length = min(int(m.group(1)), limit) if m else 0
    body = buf.split(b"\r\n\r\n", 1)[1] if b"\r\n\r\n" in buf else b""
    if len(body) < length:
        body += await asyncio.wait_for(reader.readexactly(length - len(body)), 10)
    return body[:length]


def respond(writer, code, ctype, body, extra=""):
    writer.write(
        (f"HTTP/1.1 {code}\r\nContent-Type: {ctype}\r\nContent-Length: {len(body)}\r\n"
         f"Cache-Control: no-store\r\nConnection: close\r\n{extra}\r\n").encode() + body
    )


def page(t, reason):
    data = json.dumps({**t.status(), "reason": reason})
    return PAGE.replace("__DATA__", data.replace("</", "<\\/")).encode()


PAGE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tunnel connecting…</title>
<style>
:root{--bg:#f6f7f9;--card:#fff;--fg:#1d2330;--mute:#6b7280;--line:#e5e7eb;--accent:#2563eb;--ok:#16a34a;--err:#dc2626;--warn:#d97706;--term:#0d1117;--termfg:#d6dde8}
@media (prefers-color-scheme:dark){:root{--bg:#0f1115;--card:#171a21;--fg:#e6e8ee;--mute:#8b93a3;--line:#262b36;--accent:#60a5fa;--ok:#4ade80;--err:#f87171;--warn:#fbbf24;--term:#0b0d11}}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif;padding:16px}
.card{width:100%;max-width:860px;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:24px}
.top{display:flex;align-items:center;gap:16px}
.spin{width:36px;height:36px;flex:none;border-radius:50%;border:3px solid var(--line);border-top-color:var(--accent);animation:r .9s linear infinite}
.err .spin{animation:none;border-color:var(--err)}
.ok .spin{animation:none;border-color:var(--ok)}
.login .spin{animation:none;border-color:var(--warn)}
@keyframes r{to{transform:rotate(360deg)}}
h1{font-size:18px;margin:0}
.sub{color:var(--mute);font-size:13px}
.route{margin:16px 0 12px;font:13px ui-monospace,SFMono-Regular,Menlo,monospace;display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.route span{border:1px solid var(--line);border-radius:6px;padding:3px 8px}
.route i{color:var(--mute);font-style:normal}
#term{background:var(--term);color:var(--termfg);border:1px solid var(--line);border-radius:8px;padding:8px 10px;margin:0;outline:none;cursor:text;
  font:13px/1.35 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap;word-break:break-all;height:calc(14 * 1.35em + 16px);overflow-y:auto}
#term:focus{border-color:var(--accent)}
#cur{display:inline-block;width:.6em;height:1.15em;vertical-align:text-bottom;background:var(--termfg);opacity:.35}
#term:focus #cur{opacity:1;animation:blink 1s steps(1) infinite}
@keyframes blink{50%{opacity:0}}
.down .spin{animation:pulse 2s ease-in-out infinite;border-color:var(--warn)}
@keyframes pulse{50%{opacity:.3}}
.down #term{display:none}
.hint{display:none;margin-top:4px;padding:12px 14px;border:1px dashed var(--line);border-radius:8px;font-size:13px;color:var(--mute)}
.down .hint{display:block}
.hint code{font:12px ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--fg)}
.login #term{border-color:var(--warn);box-shadow:0 0 0 3px color-mix(in srgb,var(--warn) 25%,transparent)}
.row{display:flex;justify-content:space-between;align-items:center;margin-top:14px;gap:12px}
button{font:inherit;font-size:13px;border:1px solid var(--line);background:transparent;color:var(--fg);border-radius:8px;padding:6px 14px;cursor:pointer}
button:hover{border-color:var(--accent);color:var(--accent)}
</style></head>
<body><div class="card" id="card">
  <div class="top"><div class="spin"></div><div>
    <h1 id="title">Opening SSH tunnel…</h1>
    <div class="sub" id="sub">The page will reload automatically once connected.</div>
  </div></div>
  <div class="route"><span id="local"></span><i>→ ssh →</i><span id="host"></span><i>→</i><span id="remote"></span></div>
  <div class="hint" id="hint"></div>
  <pre id="term" tabindex="0"><span id="txt"></span><span id="cur"></span></pre>
  <div class="row"><span class="sub" id="elapsed"></span><button id="retry">Reconnect</button></div>
</div>
<script>
const D = __DATA__;
const $ = id => document.getElementById(id);
$("local").textContent = location.hostname + ":" + D.listen;
$("host").textContent = D.host;
$("remote").textContent = D.remote;
let reason = D.reason, t0 = Date.now() - D.elapsed * 1000, lastReload = Date.now(), wasPrompt = false;

// ---- minimal terminal (no external deps): enough for ssh prompts (password, passphrase, yes/no)
const send = (() => { let q = Promise.resolve(); return d => { q = q.then(() =>
  fetch("/__tunnel__/input", {method: "POST", headers: {"X-Tunnel": "1"}, body: d}).catch(() => {})); }; })();
const dec = new TextDecoder(), txt = $("txt");
function write(b) {
  let t = txt.textContent;
  for (const c of dec.decode(b, {stream: true})
      .replace(/\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|\x1b[()][A-Z0-9]|\x07/g, "").replace(/\r\n/g, "\n")) {
    if (c === "\b") t = t.slice(0, -1);
    else if (c !== "\r") t += c;
  }
  txt.textContent = t.slice(-200000);
  $("term").scrollTop = 1e9;
}
const focus = () => $("term").focus();
const KEYS = {Enter: "\r", Backspace: "\x7f", Tab: "\t", Escape: "\x1b", Delete: "\x1b[3~",
  ArrowUp: "\x1b[A", ArrowDown: "\x1b[B", ArrowRight: "\x1b[C", ArrowLeft: "\x1b[D", Home: "\x1b[H", End: "\x1b[F"};
$("term").addEventListener("keydown", e => {
  if (e.metaKey || (e.ctrlKey && (e.shiftKey || e.key === "v"))) return;  // leave copy / paste to the browser
  if (KEYS[e.key]) send(KEYS[e.key]);
  else if (e.ctrlKey && /^[a-z]$/i.test(e.key)) send(String.fromCharCode(e.key.toUpperCase().charCodeAt(0) - 64));
  else if (e.key.length === 1 && !e.altKey) send(e.key);
  else return;
  e.preventDefault();
});
$("term").addEventListener("paste", e => { send(e.clipboardData.getData("text")); e.preventDefault(); });
async function stream() {
  let off = 0;
  for (;;) {
    try {
      const r = await fetch("/__tunnel__/output?from=" + off, {cache: "no-store"});
      off = +r.headers.get("X-Offset");
      const b = new Uint8Array(await r.arrayBuffer());
      if (b.length) write(b);
    } catch (e) { await new Promise(r => setTimeout(r, 1000)); }
  }
}

function render(s) {
  const login = s.prompt && s.state === "connecting";
  const down = s.state === "up" && reason === "remote";
  $("card").className = "card " + (login ? "login" : down ? "down" : s.state === "error" ? "err" : s.state === "up" ? "ok" : "");
  if (down) {
    const port = s.remote.split(":").pop();
    $("hint").innerHTML = "";
    $("hint").append("Start the service on ", Object.assign(document.createElement("code"), {textContent: s.target}),
      " (e.g. ", Object.assign(document.createElement("code"), {textContent: "python -m http.server " + port}),
      "). Checking again every few seconds; this page loads it as soon as it answers.");
  }
  const [title, sub] =
    login ? ["Login required", "Type in the terminal below to log in to " + s.host + "."] :
    down ? ["Nothing running on " + s.target, "The SSH tunnel is up, but no program is listening on port " + s.remote.split(":").pop() + " there."] :
    s.state === "up" ? ["Connected, loading…", ""] :
    s.state === "error" ? ["SSH connection failed, retrying…", (s.log || []).slice(-1)[0] || "See the terminal below."] :
    ["Opening SSH tunnel…", "The page will reload automatically once connected."];
  $("title").textContent = title;
  $("sub").textContent = sub;
  if (login && !wasPrompt) focus();
  wasPrompt = login;
  t0 = Date.now() - s.elapsed * 1000;
}
function tick() { $("elapsed").textContent = Math.floor((Date.now() - t0) / 1000) + "s"; }
async function poll() {
  try {
    const s = await (await fetch("/__tunnel__/status", {cache: "no-store"})).json();
    render(s);
    if (s.state === "up" && (reason !== "remote" || Date.now() - lastReload > 3000)) {
      lastReload = Date.now();
      location.reload();
      return;
    }
  } catch (e) {}
  setTimeout(poll, 1000);
}
$("retry").onclick = async () => {
  reason = "connecting";
  try { render(await (await fetch("/__tunnel__/retry", {method: "POST", headers: {"X-Tunnel": "1"}})).json()); } catch (e) {}
};
render(D); tick(); setInterval(tick, 500); setTimeout(poll, 500); stream();
</script></body></html>
"""


def agent_socket(value):
    """ssh_auth_sock: a socket path, or a file with `SSH_AUTH_SOCK=...;` (ssh-agent output). Read on each spawn."""
    if not value:
        return None
    path = Path(os.path.expanduser(value))
    if path.is_socket():
        return str(path)
    try:
        m = re.search(r"SSH_AUTH_SOCK=([^;\s]+)", path.read_text())
    except OSError:
        return None
    return m.group(1) if m and Path(m.group(1)).is_socket() else None


def listening_ports():
    """{port: {socket inode, ...}} of every TCP listener (any address, v4 or v6)."""
    ports = {}
    for f in ("/proc/net/tcp", "/proc/net/tcp6"):
        try:
            lines = Path(f).read_text().splitlines()[1:]
        except OSError:
            continue
        for line in lines:
            fields = line.split()
            if fields[3] == "0A":  # TCP_LISTEN
                ports.setdefault(int(fields[1].rsplit(":", 1)[1], 16), set()).add(fields[9])
    return ports


def own_ssh_pids():
    """{pid: cmdline} of this user's ssh clients."""
    pids = {}
    for d in Path("/proc").iterdir():
        try:
            if d.name.isdigit() and d.stat().st_uid == os.getuid() and (d / "comm").read_text().strip() in SSH_COMMS:
                pids[int(d.name)] = (d / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace").strip()
        except OSError:
            continue
    return pids


def parent_is_us(pid):
    """True if pid's parent is a (possibly other) running tunnel-on-demand instance."""
    try:
        ppid = int(Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[1])
        return Path(__file__).name.encode() in Path(f"/proc/{ppid}/cmdline").read_bytes()
    except (OSError, ValueError, IndexError):
        return False


def ssh_holders(ports):
    """{port: {pid: cmdline}} for listening ports held by one of this user's ssh (e.g. a manual ssh -L)."""
    listeners = listening_ports()
    inodes = {i: p for p in ports for i in listeners.get(p, ())}
    holders = {}
    for pid, cmd in own_ssh_pids().items():
        try:
            for fd in os.listdir(f"/proc/{pid}/fd"):
                link = os.readlink(f"/proc/{pid}/fd/{fd}")
                if link.startswith("socket:[") and link[8:-1] in inodes:
                    holders.setdefault(inodes[link[8:-1]], {})[pid] = cmd
        except OSError:
            continue
    return holders


async def kill_pids(pids):
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    for _ in range(20):
        if not any(Path(f"/proc/{pid}").exists() for pid in pids):
            return
        await asyncio.sleep(0.1)
    for pid in pids:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    await asyncio.sleep(0.2)


async def free_from_ssh(t, pid, cmd):
    """Release t.listen from an ssh process. A ControlMaster (it listens on a control socket)
    may carry other sessions: cancel just the forward, kill it only when nothing uses it."""
    bound = control_socket(pid)  # name in /proc/net/unix, used to count sessions
    ctl = bound and renamed_control_path(bound)
    if not ctl:
        log.warning("[%d] held by ssh pid %d (%s): killing it", t.listen, pid, cmd)
        await kill_pids([pid])
        return
    port = t.listen
    specs = dict.fromkeys([f"{port}:{t.remote}"] + [f"{port}:{h}:{port}" for h in ("0.0.0.0", "localhost", "127.0.0.1")])
    for spec in specs:
        p = await asyncio.create_subprocess_exec(
            "ssh", "-S", ctl, "-O", "cancel", "-L", spec, t.host.host,
            stdin=asyncio.subprocess.DEVNULL, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL,
        )
        await p.wait()
        if port not in listening_ports():
            log.warning("[%d] cancelled forward %s on ssh mux master pid %d", port, spec, pid)
            return
    if mux_sessions(bound) == 0:
        log.warning("[%d] held by idle ssh mux master pid %d (%s): killing it", port, pid, ctl)
        await kill_pids([pid])
    elif (port, pid) not in _left_alone:  # rechecked every RECLAIM_INTERVAL: warn once
        _left_alone.add((port, pid))
        log.warning("[%d] held by ssh mux master pid %d with open sessions (%s): left alone", port, pid, ctl)


_left_alone = set()


def control_socket(pid):
    """Path of the unix socket pid listens on (an ssh ControlMaster's ControlPath), if any."""
    inodes = set()
    try:
        for fd in os.listdir(f"/proc/{pid}/fd"):
            try:
                link = os.readlink(f"/proc/{pid}/fd/{fd}")
            except OSError:
                continue
            if link.startswith("socket:["):
                inodes.add(link[8:-1])
        lines = Path("/proc/net/unix").read_text().splitlines()[1:]
    except OSError:
        return None
    for line in lines:
        f = line.split()
        # Num RefCount Protocol Flags Type St Inode Path; Flags 00010000 = listening
        if len(f) == 8 and f[6] in inodes and int(f[3], 16) & 0x10000:
            return f[7]
    return None


def renamed_control_path(path):
    """ssh binds its ControlPath as <path>.<16 random chars> then renames it; /proc keeps the bind name."""
    base = re.sub(r"\.[A-Za-z0-9]{16}$", "", path)
    return base if not os.path.exists(path) and os.path.exists(base) else path


def mux_sessions(ctl):
    """Number of clients connected to a ControlMaster socket (connected entries in /proc/net/unix)."""
    try:
        lines = Path("/proc/net/unix").read_text().splitlines()[1:]
    except OSError:
        return 1
    return sum(1 for line in lines if line.endswith(" " + ctl) and line.split()[5] == "03")


async def reclaim(tunnels):
    """Kill ssh processes holding some of these ports (stale ssh -L), listen there instead.
    Returns the servers opened; ports held by any other program are left alone."""
    by_port = {t.listen: t for t in tunnels}
    holders = ssh_holders(by_port)
    servers = []
    for port, procs in holders.items():
        t = by_port[port]
        for pid, cmd in procs.items():
            await free_from_ssh(t, pid, cmd)
        if port in listening_ports():
            continue
        if server := await t.open():
            servers.append((by_port[port], server))
    return servers


def parse_ports(v):
    """5056, "5056", "5050-5059" or a list of those."""
    if isinstance(v, list):
        return [p for x in v for p in parse_ports(x)]
    lo, _, hi = str(v).partition("-")
    lo, hi = int(lo), int(hi or lo)
    if not 0 < lo <= hi < 65536:
        raise ValueError(f"bad port range: {v}")
    return list(range(lo, hi + 1))


async def main():
    # Ranges mean many listening sockets: lift the soft fd limit.
    _, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
    resource.setrlimit(resource.RLIMIT_NOFILE, (hard, hard))
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s", stream=sys.stdout)
    if not CONFIG.exists():
        sys.exit(f"missing config: {CONFIG}")
    with CONFIG.open("rb") as f:
        cfg = tomllib.load(f)

    hosts, tunnels = {}, []
    for entry in cfg.get("tunnel", []):
        t = {**cfg.get("defaults", {}), **entry}
        if not t.get("host"):
            sys.exit(f"tunnel {t['listen']}: no host configured")
        ports = parse_ports(t["listen"])
        if len(ports) > 1 and ":" in str(t.get("remote", "")):
            sys.exit(f"tunnel {t['listen']}: a port range needs remote without a port (e.g. \"0.0.0.0\")")
        host = Host(t)
        host = hosts.setdefault(host.ctl, host)  # entries with the same ssh settings share one master
        for p in ports:
            tunnels.append(Tunnel({**t, "listen": p, "_range": len(ports) > 1}, host))
            host.tunnels.append(tunnels[-1])
        if len(ports) > 1:
            log.info("range %s -> %s", t["listen"], t["host"])
    ports = [t.listen for t in tunnels]
    if not ports:
        sys.exit(f"no [[tunnel]] entries in {CONFIG}")
    if len(ports) != len(set(ports)):
        sys.exit("the same listen port appears in several [[tunnel]] entries")

    loop = asyncio.get_running_loop()
    done = asyncio.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, done.set)

    # Leftover ssh from a previous run of this service (master or forwards using RUNDIR).
    stale = [pid for pid, cmd in own_ssh_pids().items() if str(RUNDIR) in cmd and not parent_is_us(pid)]
    if stale:
        log.warning("killing %d leftover ssh process(es): %s", len(stale), " ".join(map(str, stale)))
        await kill_pids(stale)

    # Ports held by a stale ssh -L are taken over; any other program keeps its port.
    busy = listening_ports()
    servers = await reclaim([t for t in tunnels if t.listen in busy])
    taken = {t.listen for t, _ in servers}
    for t in tunnels:
        if t.listen not in busy and t.listen not in taken and (server := await t.open()):
            servers.append((t, server))
            taken.add(t.listen)
    skipped = [t for t in tunnels if t.listen not in taken]
    if skipped:
        log.info("skipped %d port(s) used by other programs: %s", len(skipped), " ".join(str(t.listen) for t in skipped))
    log.info("listening on %d port(s)", len(servers))

    async def reclaim_loop():
        # An ssh -L may grab a skipped port later on (once its program exits): take those over too.
        while skipped:
            await asyncio.sleep(RECLAIM_INTERVAL)
            for t, server in await reclaim(skipped):
                skipped.remove(t)
                tasks.append(asyncio.create_task(server.serve_forever()))

    tasks = [asyncio.create_task(s.serve_forever()) for _, s in servers]
    tasks.append(asyncio.create_task(reclaim_loop()))
    tasks += [asyncio.create_task(h.reap_idle()) for h in hosts.values()]
    await done.wait()
    for h in hosts.values():
        h.stop()
    await asyncio.gather(*(h.proc.wait() for h in hosts.values() if h.proc), return_exceptions=True)
    for t in tasks:
        t.cancel()


if __name__ == "__main__":
    asyncio.run(main())
