#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.3 - Verify the OpenConnect that will be
# used. The version must be v9.20 or newer, and the features line should include
# DTLS and ESP.
set -euo pipefail

# Prefer the self-built 9.21 if present, otherwise the distro's openconnect
# (fine from 9.20 on - see docs/01-why-the-distro-package-fails.md).
OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
[[ -x "$OC" ]] || OC=openconnect

"$OC" --version
