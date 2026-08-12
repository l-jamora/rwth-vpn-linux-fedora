#!/usr/bin/env bash
# docs/05-background-sessions.md - Connect to the RWTH VPN and detach into the background.
# Usage: ./connect-background.sh YOUR_USERNAME [split|full]
#
# Password and OTP are still asked interactively first; only after
# authentication succeeds does the process detach from the terminal.
# Disconnect with disconnect.sh (or: sudo kill "$(cat /run/openconnect-rwth.pid)").
set -euo pipefail

USER_ID="${1:?Usage: $0 YOUR_USERNAME [split|full]}"
MODE="${2:-split}"

case "$MODE" in
  split) GROUP="RWTH-VPN (Split Tunnel)" ;;
  full)  GROUP="RWTH-VPN (Full Tunnel)"  ;;
  *) echo "Usage: $0 YOUR_USERNAME [split|full]" >&2; exit 1 ;;
esac

sudo ~/.local/openconnect-9.21/sbin/openconnect \
  --protocol=anyconnect \
  --authgroup="$GROUP" \
  --user="$USER_ID" \
  --background \
  --pid-file=/run/openconnect-rwth.pid \
  vpn.rwth-aachen.de
