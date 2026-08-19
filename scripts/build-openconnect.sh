#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.2 - Build and install OpenConnect 9.21 into ~/.local/openconnect-9.21.
#
# Only needed if your distro still ships OpenConnect < 9.20, which fails against the
# RWTH gateway under TLS 1.3 (see docs/01-why-the-distro-package-fails.md). This
# installs into the user's home directory - no sudo needed, and the system package is
# left untouched.
set -euo pipefail

PREFIX="$HOME/.local/openconnect-9.21"

# The distro's vpnc-script; the path differs per distro.
for VPNC_SCRIPT in /etc/vpnc/vpnc-script /usr/share/vpnc-scripts/vpnc-script \
                   /usr/lib/vpnc/vpnc-script /usr/local/etc/vpnc/vpnc-script; do
  [[ -x "$VPNC_SCRIPT" ]] && break
done
[[ -x "$VPNC_SCRIPT" ]] || { echo "no vpnc-script found - run scripts/install-deps.sh first" >&2; exit 1; }

git clone https://gitlab.com/openconnect/openconnect.git ~/src/openconnect
cd ~/src/openconnect
git checkout v9.21

./autogen.sh
./configure --prefix="$PREFIX" \
            --with-vpnc-script="$VPNC_SCRIPT" \
            LDFLAGS="-Wl,-rpath,$PREFIX/lib"
make -j"$(nproc)"
make install

echo "Installed OpenConnect 9.21 to $PREFIX"
