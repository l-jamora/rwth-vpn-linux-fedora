# 2. Building OpenConnect 9.21

**Only needed if your distro ships OpenConnect < 9.20** — check with
`openconnect --version` first, see [01](01-why-the-distro-package-fails.md).

One-time setup, and `rwth-vpn.sh` does all of it for you — `./rwth-vpn.sh --setup-only`
runs exactly the steps below and then stops. This page is the manual version, for when
you want to know what is happening or to do it by hand.

The distro package stays untouched; the build lands in `~/.local/openconnect-9.21`.

## 2.1 Build dependencies

The package lists live in [`requirements.txt`](../requirements.txt) at the repo root,
one `[section]` per package manager. Run
[`scripts/install-deps.sh`](../scripts/install-deps.sh), which detects yours
(pacman / dnf / apt / zypper) and installs the matching set:

```bash
./scripts/install-deps.sh
```

On an unsupported package manager, install the equivalents by hand — GnuTLS, libxml2
and zlib headers, the autotools, and your distro's `vpnc-script` / `vpnc-scripts`
package.

`vpnc-script` is in every list because `--with-vpnc-script` below points at it: it is
the script that actually sets up routes and DNS. Its path differs per distro
(`/etc/vpnc/vpnc-script` on Fedora and Debian, `/usr/share/vpnc-scripts/vpnc-script` on
Arch), so the build scripts search the known locations.

## 2.2 Build and install

```bash
PREFIX="$HOME/.local/openconnect-9.21"

git clone https://gitlab.com/openconnect/openconnect.git ~/src/openconnect
cd ~/src/openconnect
git checkout v9.21

./autogen.sh
# --with-vpnc-script: /etc/vpnc/vpnc-script on Fedora/Debian,
#                     /usr/share/vpnc-scripts/vpnc-script on Arch.
./configure --prefix="$PREFIX" \
            --with-vpnc-script=/usr/share/vpnc-scripts/vpnc-script \
            LDFLAGS="-Wl,-rpath,$PREFIX/lib"
make -j"$(nproc)"
make install
```

`make install` needs **no** sudo — it installs into your home directory. The `rpath`
ensures the binary finds its own `libopenconnect` even under `sudo`, rather than the
system's older one.

Scripted: [`scripts/build-openconnect.sh`](../scripts/build-openconnect.sh).

## 2.3 Verify

```bash
~/.local/openconnect-9.21/sbin/openconnect --version
# OpenConnect version v9.21
```

The features line should include `DTLS, ESP`. Scripted:
[`scripts/verify-openconnect.sh`](../scripts/verify-openconnect.sh).
