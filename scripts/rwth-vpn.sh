#!/usr/bin/env bash
# Minimal convenience script for connecting to the RWTH VPN via OpenConnect 9.21.
# Usage: rwth-vpn [split|full]
#
# Install with:
#   cp rwth-vpn.sh ~/bin/rwth-vpn && chmod +x ~/bin/rwth-vpn
# then edit USER_ID below (in the installed copy) once.
set -euo pipefail

OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
USER_ID="YOUR_USERNAME"

[[ -x "$OC" ]] || { echo "OpenConnect 9.21 missing at $OC - see build-openconnect.sh." >&2; exit 1; }

case "${1:-split}" in
  split) GROUP="RWTH-VPN (Split Tunnel)" ;;
  full)  GROUP="RWTH-VPN (Full Tunnel)"  ;;
  *) echo "Usage: $0 [split|full]" >&2; exit 1 ;;
esac

echo "Connecting to RWTH VPN - $GROUP"
exec sudo "$OC" \
  --protocol=anyconnect \
  --authgroup="$GROUP" \
  --user="$USER_ID" \
  vpn.rwth-aachen.de
