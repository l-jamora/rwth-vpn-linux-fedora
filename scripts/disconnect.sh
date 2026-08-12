#!/usr/bin/env bash
# docs/05-background-sessions.md - Disconnect the backgrounded RWTH VPN session started by
# connect-background.sh.
set -euo pipefail

PID_FILE="/run/openconnect-rwth.pid"

[[ -f "$PID_FILE" ]] || { echo "No pid file at $PID_FILE - is the VPN running?" >&2; exit 1; }

sudo kill "$(cat "$PID_FILE")"
