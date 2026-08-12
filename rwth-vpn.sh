#!/usr/bin/env bash
# rwth-vpn.sh - one-run CLI for the RWTH VPN on Fedora.
#
# Does everything the README describes, in a single command: picks a working
# OpenConnect (>= 9.20, building 9.21 into ~/.local if the system package is too
# old - see docs/01-why-the-fedora-package-fails.md), then connects to vpn.rwth-aachen.de.
#
#   ./rwth-vpn.sh -u ab123456              # split tunnel, foreground
#   ./rwth-vpn.sh -u ab123456 -g full -b   # full tunnel, background
#   ./rwth-vpn.sh --status                 # is the tunnel up?
#   ./rwth-vpn.sh --disconnect             # tear down a background session
#
# The username is remembered in ~/.config/rwth-vpn.conf after the first run.
set -euo pipefail

GATEWAY="vpn.rwth-aachen.de"
VERSION="9.21"
PREFIX="$HOME/.local/openconnect-$VERSION"
SRC_DIR="$HOME/src/openconnect"
PID_FILE="/run/openconnect-rwth.pid"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/rwth-vpn.conf"
REQUIREMENTS="$(dirname "$(readlink -f "$0")")/requirements.txt"
MIN_MAJOR=9
MIN_MINOR=20

USER_ID=""
MODE="split"
BACKGROUND=0
ACTION="connect"
FORCE_BUILD=0
ASSUME_YES=0
VERBOSE=0

die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<EOF
Usage: ${0##*/} [options]

Options:
  -u, --user ID       RWTH SSO username (e.g. ab123456). Saved for next time.
  -g, --group MODE    Tunnel group: split (default) or full.
  -b, --background    Detach after authentication; disconnect with --disconnect.
  -s, --status        Show tunnel state and exit.
  -d, --disconnect    Kill a background session and exit.
      --groups        Ask the gateway for the current tunnel-group names and exit.
      --setup-only    Build/verify OpenConnect $VERSION, then exit without connecting.
      --force-build   Rebuild OpenConnect $VERSION even if it is already installed.
  -y, --yes           Don't ask before installing packages or building.
  -v, --verbose       Pass -v to openconnect.
  -h, --help          This text.

Tunnel groups:
  split  RWTH-internal addresses only - the rest of your traffic stays local.
  full   All traffic via RWTH - needed when a service checks your public IP
         (licensed journals, e-books).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user)       USER_ID="${2:?--user needs a value}"; shift 2 ;;
    -g|--group)      MODE="${2:?--group needs a value}";   shift 2 ;;
    -b|--background) BACKGROUND=1;      shift ;;
    -s|--status)     ACTION="status";   shift ;;
    -d|--disconnect) ACTION="disconnect"; shift ;;
    --groups)        ACTION="groups";   shift ;;
    --setup-only)    ACTION="setup";    shift ;;
    --force-build)   FORCE_BUILD=1;     shift ;;
    -y|--yes)        ASSUME_YES=1;      shift ;;
    -v|--verbose)    VERBOSE=1;         shift ;;
    -h|--help)       usage; exit 0 ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
done

case "$MODE" in
  split) GROUP="RWTH-VPN (Split Tunnel)" ;;
  full)  GROUP="RWTH-VPN (Full Tunnel)"  ;;
  *) die "--group must be 'split' or 'full', not '$MODE'" ;;
esac

confirm() {
  (( ASSUME_YES )) && return 0
  local reply
  read -r -p "$1 [Y/n] " reply
  [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# ---------------------------------------------------------------- openconnect

# Prints the version of $1 as "major minor", or nothing if it isn't usable.
oc_version() {
  local out
  out="$("$1" --version 2>/dev/null | head -n1)" || return 1
  [[ "$out" =~ v?([0-9]+)\.([0-9]+) ]] || return 1
  printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

# True if the binary is new enough to survive the STRAP/TLS 1.3 bug (docs/01).
oc_is_new_enough() {
  local major minor
  read -r major minor < <(oc_version "$1") || return 1
  [[ -n "${major:-}" ]] || return 1
  (( major > MIN_MAJOR || (major == MIN_MAJOR && minor >= MIN_MINOR) ))
}

install_build_deps() {
  local packages=()
  if [[ -f "$REQUIREMENTS" ]]; then
    mapfile -t packages < <(grep -v -e '^#' -e '^[[:space:]]*$' "$REQUIREMENTS")
  else
    # Fallback, so the script still works when copied out of the repo alone.
    packages=(gnutls-devel libxml2-devel zlib-ng-compat-devel gcc make autoconf
              automake libtool gettext-devel pkgconf-pkg-config vpnc-script)
  fi

  info "Installing build dependencies (needs sudo): ${packages[*]}"
  sudo dnf install -y --setopt=install_weak_deps=False "${packages[@]}"
}

build_openconnect() {
  install_build_deps

  if [[ -d "$SRC_DIR/.git" ]]; then
    info "Updating existing checkout in $SRC_DIR"
    git -C "$SRC_DIR" fetch --tags --quiet origin
  else
    info "Cloning OpenConnect into $SRC_DIR"
    mkdir -p "$(dirname "$SRC_DIR")"
    git clone --quiet https://gitlab.com/openconnect/openconnect.git "$SRC_DIR"
  fi

  git -C "$SRC_DIR" checkout --quiet "v$VERSION"

  info "Building OpenConnect $VERSION (a few minutes)"
  (
    cd "$SRC_DIR"
    ./autogen.sh
    # The rpath makes the binary find its own libopenconnect even under sudo,
    # instead of the system's older one.
    ./configure --prefix="$PREFIX" \
                --with-vpnc-script=/etc/vpnc/vpnc-script \
                LDFLAGS="-Wl,-rpath,$PREFIX/lib"
    make -j"$(nproc)"
    make install          # into $HOME - deliberately no sudo
  )

  oc_is_new_enough "$PREFIX/sbin/openconnect" \
    || die "build finished but $PREFIX/sbin/openconnect does not report >= $MIN_MAJOR.$MIN_MINOR"
  info "Installed OpenConnect $VERSION to $PREFIX"
}

# Sets OC to a usable openconnect, building one if necessary.
resolve_openconnect() {
  local own="$PREFIX/sbin/openconnect"

  if (( FORCE_BUILD )); then
    build_openconnect
    OC="$own"
    return
  fi

  if [[ -x "$own" ]] && oc_is_new_enough "$own"; then
    OC="$own"
    return
  fi

  local sys
  if sys="$(command -v openconnect)" && oc_is_new_enough "$sys"; then
    info "Using system OpenConnect ($sys) - new enough, no build needed"
    OC="$sys"
    return
  fi

  if [[ -n "${sys:-}" ]]; then
    warn "System OpenConnect at $sys is older than $MIN_MAJOR.$MIN_MINOR and will fail against $GATEWAY (docs/01-why-the-fedora-package-fails.md)."
  fi
  confirm "Build OpenConnect $VERSION into $PREFIX now?" \
    || die "no usable OpenConnect - aborting"
  build_openconnect
  OC="$own"
}

# --------------------------------------------------------------------- config

load_config() {
  # shellcheck source=/dev/null
  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
  [[ -n "$USER_ID" ]] || USER_ID="${RWTH_VPN_USER:-}"
}

save_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  printf 'RWTH_VPN_USER=%q\n' "$USER_ID" > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
}

require_user() {
  if [[ -z "$USER_ID" ]]; then
    read -r -p "RWTH username (e.g. ab123456): " USER_ID
    [[ -n "$USER_ID" ]] || die "no username given"
  fi
  save_config
}

# -------------------------------------------------------------------- actions

running_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(sudo cat "$PID_FILE" 2>/dev/null)" || return 1
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && printf '%s\n' "$pid"
}

do_status() {
  local pid
  if pid="$(running_pid)"; then
    info "Background session running (pid $pid)"
  else
    info "No background session recorded at $PID_FILE"
  fi
  if ip link show tun0 >/dev/null 2>&1; then
    ip -brief addr show tun0
    resolvectl status tun0 2>/dev/null | sed -n '/DNS Servers/p' || true
  else
    echo "tun0 does not exist - not connected."
  fi
}

do_disconnect() {
  local pid
  pid="$(running_pid)" || die "no running VPN found (pid file: $PID_FILE)"
  info "Stopping OpenConnect (pid $pid)"
  sudo kill "$pid"
}

do_connect() {
  require_user
  local args=(
    --protocol=anyconnect
    --authgroup="$GROUP"
    --user="$USER_ID"
  )
  (( VERBOSE ))    && args+=(-v)
  (( BACKGROUND )) && args+=(--background --pid-file="$PID_FILE")

  info "Connecting to $GATEWAY as $USER_ID - $GROUP"
  echo "You will be asked for your VPN password, then separately for the 6-digit OTP."
  if (( BACKGROUND )); then
    sudo "$OC" "${args[@]}" "$GATEWAY"
    info "Detached. Stop it with: ${0##*/} --disconnect"
  else
    echo "Keep this terminal open; Ctrl+C disconnects."
    exec sudo "$OC" "${args[@]}" "$GATEWAY"
  fi
}

# ----------------------------------------------------------------------- main

load_config

case "$ACTION" in
  status)     do_status ;;
  disconnect) do_disconnect ;;
  groups)     resolve_openconnect; "$OC" --authenticate "$GATEWAY" ;;
  setup)      resolve_openconnect; "$OC" --version ;;
  connect)    resolve_openconnect; do_connect ;;
esac
