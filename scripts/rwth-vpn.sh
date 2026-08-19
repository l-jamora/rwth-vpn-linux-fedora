#!/usr/bin/env bash
# Minimal convenience script for connecting to the RWTH VPN via OpenConnect.
# Usage: rwth-vpn [split|full]
#
# Install with:
#   cp rwth-vpn.sh ~/bin/rwth-vpn && chmod +x ~/bin/rwth-vpn
# then edit USER_ID below (in the installed copy) once.
set -euo pipefail

# Prefer the self-built 9.21 if present, otherwise the distro's openconnect
# (fine from 9.20 on - see docs/01-why-the-distro-package-fails.md).
OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
[[ -x "$OC" ]] || OC=openconnect
USER_ID="YOUR_USERNAME"

command -v "$OC" >/dev/null || { echo "no openconnect found - see build-openconnect.sh." >&2; exit 1; }

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
