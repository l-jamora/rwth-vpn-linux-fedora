#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.3 - Verify the self-built OpenConnect 9.21 is installed correctly.
# The version string should read "OpenConnect version v9.21" and the features
# line should include DTLS and ESP.
set -euo pipefail

~/.local/openconnect-9.21/sbin/openconnect --version
