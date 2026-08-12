#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.1 - install the packages needed to
# compile OpenConnect 9.21. The package list lives in requirements.txt at the
# repo root so the docs, this script and rwth-vpn.sh can't drift apart.
set -euo pipefail

REQUIREMENTS="$(dirname "$(readlink -f "$0")")/../requirements.txt"

[[ -f "$REQUIREMENTS" ]] || { echo "requirements.txt not found at $REQUIREMENTS" >&2; exit 1; }

mapfile -t PACKAGES < <(grep -v -e '^#' -e '^[[:space:]]*$' "$REQUIREMENTS")

sudo dnf install -y --setopt=install_weak_deps=False "${PACKAGES[@]}"
