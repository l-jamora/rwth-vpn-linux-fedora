#!/usr/bin/env bash
# docs/03-tunnel-groups.md - Query the RWTH VPN gateway for the current list of tunnel groups
# (e.g. "RWTH-VPN (Full Tunnel)" / "RWTH-VPN (Split Tunnel)"). Useful if the
# group names ever change on the server side.
set -euo pipefail

# Prefer the self-built 9.21 if present, otherwise the distro's openconnect
# (fine from 9.20 on - see docs/01-why-the-distro-package-fails.md).
OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
[[ -x "$OC" ]] || OC=openconnect

"$OC" --authenticate vpn.rwth-aachen.de
