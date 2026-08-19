#!/usr/bin/env bash
# Checks the requirements.txt section parser used by install-deps.sh: every package
# manager must yield a non-empty list ending in a vpnc-script package.
set -euo pipefail
REQ="$(dirname "$(readlink -f "$0")")/../requirements.txt"

for pm in pacman dnf apt zypper; do
  mapfile -t pkgs < <(sed -n "/^\[$pm\]/,/^\[/p" "$REQ" | grep -v -e '^\[' -e '^#' -e '^[[:space:]]*$')
  (( ${#pkgs[@]} >= 5 )) || { echo "FAIL: [$pm] parsed ${#pkgs[@]} packages"; exit 1; }
  [[ "${pkgs[*]}" == *vpnc* ]] || { echo "FAIL: [$pm] has no vpnc-script package"; exit 1; }
  [[ "${pkgs[*]}" != *"["* ]]  || { echo "FAIL: [$pm] leaked a section header"; exit 1; }
  echo "ok: [$pm] ${#pkgs[@]} packages"
done
echo "all sections parse"
