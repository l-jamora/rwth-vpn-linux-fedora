#!/usr/bin/env bash
# docs/02-building-openconnect.md section 2.2 - Build and install OpenConnect 9.21 into ~/.local/openconnect-9.21.
#
# The Fedora-packaged OpenConnect (9.12) fails against the RWTH gateway under
# TLS 1.3 (see docs/01-why-the-fedora-package-fails.md), so we build our own copy. This installs into
# the user's home directory - no sudo needed, and the system package is left
# untouched.
set -euo pipefail

PREFIX="$HOME/.local/openconnect-9.21"

git clone https://gitlab.com/openconnect/openconnect.git ~/src/openconnect
cd ~/src/openconnect
git checkout v9.21

./autogen.sh
./configure --prefix="$PREFIX" \
            --with-vpnc-script=/etc/vpnc/vpnc-script \
            LDFLAGS="-Wl,-rpath,$PREFIX/lib"
make -j"$(nproc)"
make install

echo "Installed OpenConnect 9.21 to $PREFIX"
