#!/usr/bin/env bash
# docs/04-connecting.md - Connect to the RWTH VPN in the foreground.
# Usage: ./connect.sh YOUR_USERNAME [split|full]
#
# The terminal stays occupied while connected and holds the tunnel open;
# disconnect with Ctrl+C.
set -euo pipefail

# Prefer the self-built 9.21 if present, otherwise the distro's openconnect
# (fine from 9.20 on - see docs/01-why-the-distro-package-fails.md).
OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
[[ -x "$OC" ]] || OC=openconnect

USER_ID="${1:?Usage: $0 YOUR_USERNAME [split|full]}"
MODE="${2:-split}"

case "$MODE" in
  split) GROUP="RWTH-VPN (Split Tunnel)" ;;
  full)  GROUP="RWTH-VPN (Full Tunnel)"  ;;
  *) echo "Usage: $0 YOUR_USERNAME [split|full]" >&2; exit 1 ;;
esac

sudo "$OC" \
  --protocol=anyconnect \
  --authgroup="$GROUP" \
  --user="$USER_ID" \
  vpn.rwth-aachen.de
