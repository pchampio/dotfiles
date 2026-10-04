#!/usr/bin/env bash
# Install tunnel-on-demand as a systemd user service.
#   ./install.sh              install / update and (re)start
#   ./install.sh --uninstall  stop and remove the service (config is kept)
set -euo pipefail
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
. "$DIR/../../install/inc/functions"

NAME=tunnel-on-demand
UNIT="$HOME/.config/systemd/user/$NAME.service"
CONF_DIR="$HOME/.config/$NAME"

if [[ ${1:-} == --uninstall ]]; then
  systemctl --user disable --now "$NAME" 2>/dev/null || true
  rm -f "$UNIT"
  systemctl --user daemon-reload
  success "[$NAME] Uninstalled (config kept in $CONF_DIR)"
  exit
fi

PYTHON=/usr/bin/python3
"$PYTHON" -c 'import sys, tomllib; sys.exit(sys.version_info < (3, 11))' 2>/dev/null ||
  { error "$PYTHON >= 3.11 required"; exit 1; }
command -v ssh >/dev/null || { error "ssh not found"; exit 1; }

mkdir -p "$CONF_DIR" "$(dirname "$UNIT")"
if [[ ! -f $CONF_DIR/config.toml ]]; then
  cp "$DIR/config.example.toml" "$CONF_DIR/config.toml"
  explain "Created $CONF_DIR/config.toml"
fi

cat >"$UNIT" <<EOF
[Unit]
Description=On-demand SSH tunnels (opens ssh -L on first connection)
# Only run inside a desktop login session (not at boot), stop on logout.
PartOf=graphical-session.target
After=graphical-session.target

[Service]
# Let autostarted apps grab their ports first: ports already in use are skipped.
ExecStartPre=/bin/sleep 10
ExecStart=$PYTHON -u $DIR/tunnel_on_demand.py
Restart=always
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user disable "$NAME" 2>/dev/null || true  # drop links from older installs (default.target)
systemctl --user enable "$NAME"
systemctl --user restart "$NAME"
success "[$NAME] Running. Logs: journalctl --user -u $NAME -f"
