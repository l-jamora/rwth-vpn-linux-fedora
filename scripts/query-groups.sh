#!/usr/bin/env bash
# docs/03-tunnel-groups.md - Query the RWTH VPN gateway for the current list of tunnel groups
# (e.g. "RWTH-VPN (Full Tunnel)" / "RWTH-VPN (Split Tunnel)"). Useful if the
# group names ever change on the server side.
set -euo pipefail

~/.local/openconnect-9.21/sbin/openconnect --authenticate vpn.rwth-aachen.de
