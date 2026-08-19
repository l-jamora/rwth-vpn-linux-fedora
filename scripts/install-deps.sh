#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.1 - install the packages needed to
# compile OpenConnect 9.21. The package lists live in requirements.txt at the repo
# root, one section per package manager, so the docs, this script and rwth-vpn.sh
# can't drift apart.
set -euo pipefail

REQUIREMENTS="$(dirname "$(readlink -f "$0")")/../requirements.txt"
[[ -f "$REQUIREMENTS" ]] || { echo "requirements.txt not found at $REQUIREMENTS" >&2; exit 1; }

# First package manager found wins. Add a distro by adding a case here and a
# matching [section] in requirements.txt.
if   command -v pacman >/dev/null; then PM=pacman; INSTALL=(sudo pacman -S --needed --noconfirm)
elif command -v dnf    >/dev/null; then PM=dnf;    INSTALL=(sudo dnf install -y --setopt=install_weak_deps=False)
elif command -v apt    >/dev/null; then PM=apt;    INSTALL=(sudo apt install -y --no-install-recommends)
elif command -v zypper >/dev/null; then PM=zypper; INSTALL=(sudo zypper install -y --no-recommends)
else
  echo "No supported package manager found (pacman/dnf/apt/zypper)." >&2
  echo "Install the equivalents of the packages in $REQUIREMENTS by hand." >&2
  exit 1
fi

# Everything between "[$PM]" and the next "[" line, comments and blanks dropped.
mapfile -t PACKAGES < <(sed -n "/^\[$PM\]/,/^\[/p" "$REQUIREMENTS" | grep -v -e '^\[' -e '^#' -e '^[[:space:]]*$')
[[ ${#PACKAGES[@]} -gt 0 ]] || { echo "no [$PM] section in $REQUIREMENTS" >&2; exit 1; }

echo "==> $PM: installing ${PACKAGES[*]}"
"${INSTALL[@]}" "${PACKAGES[@]}"
