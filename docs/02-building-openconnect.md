# 2. Building OpenConnect 9.21

One-time setup, and `rwth-vpn.sh` does all of it for you — `./rwth-vpn.sh --setup-only`
runs exactly the steps below and then stops. This page is the manual version, for when
you want to know what is happening or to do it by hand.

The Fedora package stays untouched; the build lands in `~/.local/openconnect-9.21`.

## 2.1 Build dependencies

The package list lives in [`requirements.txt`](../requirements.txt) at the repo root:

```bash
sudo dnf install -y --setopt=install_weak_deps=False $(grep -v '^#' requirements.txt)
```

or run [`scripts/install-deps.sh`](../scripts/install-deps.sh), which does the same.

`vpnc-script` is in that list because `--with-vpnc-script` below points at
`/etc/vpnc/vpnc-script`, which that package provides.

## 2.2 Build and install

```bash
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
```

`make install` needs **no** sudo — it installs into your home directory. The `rpath`
ensures the binary finds its own `libopenconnect` even under `sudo`, rather than the
system's 9.12.

Scripted: [`scripts/build-openconnect.sh`](../scripts/build-openconnect.sh).

## 2.3 Verify

```bash
~/.local/openconnect-9.21/sbin/openconnect --version
# OpenConnect version v9.21
```

The features line should include `DTLS, ESP`. Scripted:
[`scripts/verify-openconnect.sh`](../scripts/verify-openconnect.sh).
