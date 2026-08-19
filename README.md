# RWTH VPN on Linux with OpenConnect

For RWTH Aachen students and staff on Linux who need access to the university VPN.
Cisco Secure Client (AnyConnect) has no supported Linux package for most distros, but
OpenConnect speaks the same AnyConnect protocol and connects to `vpn.rwth-aachen.de` —
including two-factor authentication.

Verified 12 Aug 2026 on Fedora 44, and on CachyOS (Arch) with the distro's OpenConnect
9.21.

> **The one requirement:** OpenConnect **≥ 9.20**. Older builds authenticate fine and
> then die with a 401 when the tunnel opens — a TLS 1.3 channel-binding bug fixed
> upstream in 9.20. [The full story](docs/01-why-the-distro-package-fails.md).
>
> Rolling distros (Arch, CachyOS, openSUSE Tumbleweed) already ship 9.20+, so there is
> nothing to build. Stable distros may not — Fedora 44 still ships 9.12.
> `rwth-vpn.sh` checks: if your system OpenConnect is new enough it uses it, otherwise
> it builds 9.21 into `~/.local` and leaves the distro package alone.

Package installs use pacman, dnf, apt or zypper, whichever is present. On anything
else, install the equivalents of [`requirements.txt`](requirements.txt) by hand.

---

## Quick start

```bash
git clone https://github.com/…/rwth-vpn-linux.git
cd rwth-vpn-linux
./rwth-vpn.sh -u ab123456
```

If your distro's OpenConnect is ≥ 9.20 this connects immediately. Otherwise the first
run installs the build dependencies from [`requirements.txt`](requirements.txt) (asking
first, `sudo`) and compiles OpenConnect 9.21 — a few minutes, once. Every later run
connects straight away.

You are asked for your VPN password, then — in a **separate** prompt — for the 6-digit
OTP from the RWTH IdM Selfservice token. The terminal then holds the tunnel open;
`Ctrl+C` disconnects.

## Using the script

```bash
./rwth-vpn.sh -u ab123456              # split tunnel, foreground
./rwth-vpn.sh                          # username remembered from last time
./rwth-vpn.sh -g full                  # all traffic via RWTH
./rwth-vpn.sh -b                       # detach after authentication
./rwth-vpn.sh --status                 # tun0 address, DNS servers, background pid
./rwth-vpn.sh --disconnect             # stop a backgrounded session
./rwth-vpn.sh --groups                 # ask the gateway for current group names
./rwth-vpn.sh --setup-only             # build/verify OpenConnect, don't connect
./rwth-vpn.sh --help                   # all options
```

| Option | Meaning |
|---|---|
| `-u, --user ID` | RWTH SSO username (`ab123456`). Saved to `~/.config/rwth-vpn.conf`, so you only pass it once. |
| `-g, --group split\|full` | **split** (default) routes only RWTH-internal addresses through the VPN and keeps the rest of your traffic local and fast. **full** sends everything via RWTH — needed when a service checks that your public IP belongs to the university, e.g. licensed journals and e-books. |
| `-b, --background` | Detach once authentication succeeds; pid in `/run/openconnect-rwth.pid`. |
| `-y, --yes` | Don't ask before installing packages or building. |
| `-v, --verbose` | Pass `-v` to openconnect. |
| `--force-build` | Rebuild 9.21 even if it is already installed. |

Nothing is installed system-wide except the build dependencies, and those only if a
build is actually needed: the OpenConnect build lives in `~/.local/openconnect-9.21`,
its source in `~/src/openconnect`.

Something not working? → [Troubleshooting](docs/07-troubleshooting.md).

---

## What's in here

```
.
├── README.md                 you are here
├── requirements.txt          build packages, one [section] per package manager
├── rwth-vpn.sh               the one-run CLI: sets up, connects, disconnects
├── docs/
│   ├── 01-why-the-distro-package-fails.md   the STRAP / TLS 1.3 bug below 9.20
│   ├── 02-building-openconnect.md           building 9.21 by hand, if you must
│   ├── 03-tunnel-groups.md                  split vs. full, exact --authgroup values
│   ├── 04-connecting.md                     the raw openconnect command, 2FA flow
│   ├── 05-background-sessions.md            --background and how to tear it down
│   ├── 06-networkmanager.md                 when GNOME click-to-connect works
│   ├── 07-troubleshooting.md                symptom → cause table
│   └── appendix.md                          group discovery, Cisco fallback, sources
└── scripts/
    ├── install-deps.sh       A: detect the package manager, install from requirements.txt
    ├── build-openconnect.sh  B: clone, configure, make, install into ~/.local
    ├── verify-openconnect.sh C: print the built version and features
    ├── query-groups.sh       ask the gateway for the tunnel-group list
    ├── discover-groups.sh    the same, raw: curl the aggregate-auth XML
    ├── connect.sh            connect in the foreground
    ├── connect-background.sh connect and detach
    ├── disconnect.sh         kill the backgrounded session
    ├── rwth-vpn.sh           a minimal hardcoded wrapper, if you prefer that
    └── test-install-deps.sh  checks requirements.txt parses for every package manager
```

`docs/` is the manual route — read it if you want to know what `rwth-vpn.sh` is doing,
or if you'd rather do it yourself. `scripts/` breaks the same steps into one small,
readable script per step; A → B → C is the setup order.
