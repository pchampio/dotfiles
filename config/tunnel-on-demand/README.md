# tunnel-on-demand

Opens `ssh -L` tunnels only when you use them. You open `http://localhost:8700/`
and the tunnel to `ampere:8700` opens by itself. While it connects, the browser
shows a "connecting…" page, which reloads once the tunnel is up.

It's a single Python file (stdlib only, Python ≥ 3.11) run as a systemd user
service. It listens on every configured port itself, keeps **one** ssh
connection per host, and adds each port's forward to that connection the
first time the port is used.

## Install

```sh
./install.sh               # install / update, (re)start
./install.sh --uninstall   # remove the service (config is kept)
```

The service starts with your desktop session (`graphical-session.target`),
not at boot.

```sh
systemctl --user restart tunnel-on-demand   # after editing the config
journalctl --user -u tunnel-on-demand -f    # logs
```

## Config

`~/.config/tunnel-on-demand/config.toml` (created from `config.example.toml`):

```toml
[defaults]
host = "ampere.ch.themama.ai"
ssh_auth_sock = "~/.ssh-agent-thing"   # agent socket, or a file with ssh-agent output
# identity_file = "~/.ssh/id_ed25519"  # optional private key
# idle_timeout = 900                   # close ssh after N s without connections (0 = never)
# ssh_args = ["-p", "22"]

[[tunnel]]
listen = "5050-5059"   # 5056 | "5050-5059" | [5056, "8000-8999"]
remote = "0.0.0.0"     # no port = same port as listen; "addr:port" for a single port

[[tunnel]]
listen = "8000-8999"
remote = "0.0.0.0"
```

`host`, `identity_file`, `ssh_auth_sock` and `ssh_args` can also be set per `[[tunnel]]`.

## Behaviour

- **Login:** if the agent or key isn't enough (expired agent, passphrase,
  password, new host key), the connecting page shows a small terminal where
  you log in. You log in once per host, because all its ports share one
  connection.
- **Nothing running on the remote port:** the page says so ("Nothing running
  on ampere…:8701") and loads it as soon as the port answers.
- **Ports already in use** at startup are skipped. The exception is a port
  held by one of your `ssh -L`: a plain ssh is killed and the service takes
  the port. A ControlMaster has just that forward cancelled, and is killed
  only if no session uses it. Skipped ports are re-checked every 30 s.
- **Ports the service holds** can't be used by local programs started later.
  Restart the service to free them.
- **Clients that aren't browsers** (curl…) wait up to 30 s for the tunnel,
  then get a plain-text 503 that explains why.

## Files

| | |
|---|---|
| `tunnel_on_demand.py` | the service |
| `config.example.toml` | config template |
| `install.sh` | installs `~/.config/systemd/user/tunnel-on-demand.service` |
| `$XDG_RUNTIME_DIR/tunnel-on-demand/` | ssh control socket and per-port forward sockets |
