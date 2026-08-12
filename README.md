# RWTH VPN on Fedora with OpenConnect

A guide for RWTH Aachen students and staff who run Fedora Linux and need access to the
university VPN. Cisco Secure Client (AnyConnect) is not supported on Fedora, but
OpenConnect speaks the same AnyConnect protocol and connects to `vpn.rwth-aachen.de` —
including two-factor authentication.

Verified 12 Aug 2026 on Fedora 44.

> **The key finding up front:** the OpenConnect **9.12** that Fedora ships **does not
> work** with the RWTH gateway. You have to build version **9.21** yourself. Section 1
> explains why. Skipping it costs hours chasing a failure that looks like a password
> problem but isn't one.
>
> If your Fedora release already ships OpenConnect **9.20 or newer**
> (`openconnect --version`), you can skip section 2 and use the system binary — plain
> `openconnect` instead of the long path in every command below.

---

## 1. Why the Fedora package fails

With `openconnect` from the Fedora repos, authentication completes cleanly — password
accepted, 2FA code accepted — and then the actual tunnel setup fails:

```
Got inappropriate HTTP CONNECT response: HTTP/1.1 401 Unauthorized
Creating SSL connection failed
Cookie was rejected by server; exiting.
```

The cause is **STRAP**, Cisco's binding of the session token to the TLS channel.
OpenConnect 9.12 derives the STRAP signature from the TLS *Finished* message. Under
**TLS 1.3** — and the RWTH ASA negotiates TLS 1.3 — that is the wrong binding. The ASA
cannot verify the signature and discards the cookie at the moment the tunnel is opened.

Fixed upstream in commit `94e0b16c` *"Use RFC9266 'tls-exporter' channel bindings for
Cisco STRAP with TLSv1.3"*, shipped from **version 9.20** onwards. Fedora 44 ships 9.12,
`updates-testing` included. So there is no way around building it yourself.

Things that do **not** help (all tested): a different `--useragent`, `--version-string`,
`--os=win`, forcing IPv4, or the choice of tunnel group. All fail identically with the
same 401.

---

## 2. Building OpenConnect 9.21

One-time setup. The Fedora package stays untouched; the build lands in
`~/.local/openconnect-9.21`.

### 2.1 Build dependencies

```bash
sudo dnf install -y --setopt=install_weak_deps=False \
  gnutls-devel libxml2-devel zlib-ng-compat-devel \
  gcc make autoconf automake libtool gettext-devel pkgconf-pkg-config
```

### 2.2 Build and install

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

The `vpnc-script` referenced by `--with-vpnc-script` comes from the `vpnc-script`
package; install it with `sudo dnf install vpnc-script` if the file is missing.

### 2.3 Verify

```bash
~/.local/openconnect-9.21/sbin/openconnect --version
# OpenConnect version v9.21
```

The features line should include `DTLS, ESP`.

---

## 3. The tunnel groups

Cisco Secure Client shows a dropdown with two entries. The exact values for
`--authgroup`:

| Cisco dropdown | value for `--authgroup` | internal tunnel group |
|---|---|---|
| Full Tunnel (all traffic via RWTH) | `RWTH-VPN (Full Tunnel)` | `TunnelGroup_RWTH_Full` |
| Split Tunnel (RWTH-internal addresses only) | `RWTH-VPN (Split Tunnel)` | — |

The hyphen in `RWTH-VPN`, the space and the parentheses are all part of the name — so
always quote it. Get it wrong and OpenConnect reports
`Auth choice "..." not available` and falls back to asking interactively.

Query the list yourself at any time:

```bash
~/.local/openconnect-9.21/sbin/openconnect --authenticate vpn.rwth-aachen.de
```

**Which one do you want?** Split Tunnel routes only RWTH-internal addresses through the
VPN — enough for university file servers, internal web services and licence servers,
and it keeps the rest of your traffic local and fast. Full Tunnel sends *all* traffic
through RWTH; you need it when a service checks that your public IP belongs to the
university, which is the usual case for licensed journals and e-book access.

---

## 4. Connecting

Your username is the RWTH identifier you use for the VPN — for most people the
`ab123456` style RWTH Single Sign-On ID. Substitute it for `YOUR_USERNAME` below.

```bash
sudo ~/.local/openconnect-9.21/sbin/openconnect \
  --protocol=anyconnect \
  --authgroup="RWTH-VPN (Split Tunnel)" \
  --user=YOUR_USERNAME \
  vpn.rwth-aachen.de
```

Full tunnel: same command with `--authgroup="RWTH-VPN (Full Tunnel)"`.

No `--useragent` is needed. Version 9.21 sends a default User-Agent the RWTH ASA
accepts. (With 9.12 that was not the case — see section 8.)

### What happens

1. `Password:` → type your VPN password (input stays invisible, that is normal).
2. Then comes **a second, separate prompt** for the 6-digit code:

   ```
   Einmal-Passwort eingeben.
   Token im IdM Selfservice registrieren.

   Enter One-Time-Password.
   Set up tokens in IdM Selfservice.
   Response:
   ```

   Type the current token at `Response:`. Password and code are asked **one after the
   other**, not concatenated into one field. If you have not set up a token yet, do so
   in the RWTH IdM Selfservice first — the VPN requires 2FA.
3. Success looks like this:

   ```
   Got CONNECT response: HTTP/1.1 200 OK
   CSTP connected. DPD 30, Keepalive 20
   Established DTLS connection (using GnuTLS).
   Configured as 172.21.x.x + 2a00:8a60:...
   Session authentication will expire at ...
   ```

The terminal stays occupied afterwards and shows the log. **Do not close it** — it holds
the tunnel open. Disconnect with `Ctrl+C`.

### Verify

In a **second** terminal:

```bash
ip addr show tun0                 # an RWTH address in 172.21.x.x
resolvectl status tun0            # RWTH DNS servers
curl -s https://ifconfig.me       # full tunnel only: an RWTH public IP
```

---

## 5. Running it in the background

```bash
sudo ~/.local/openconnect-9.21/sbin/openconnect \
  --protocol=anyconnect \
  --authgroup="RWTH-VPN (Split Tunnel)" \
  --user=YOUR_USERNAME \
  --background \
  --pid-file=/run/openconnect-rwth.pid \
  vpn.rwth-aachen.de
```

Password and token are still asked interactively first; only then does the process
detach from the terminal.

Disconnect:

```bash
sudo kill "$(cat /run/openconnect-rwth.pid)"
```

---

## 6. Convenience script

```bash
mkdir -p ~/bin
cat > ~/bin/rwth-vpn <<'EOF'
#!/usr/bin/env bash
# RWTH VPN via OpenConnect 9.21.  Usage:  rwth-vpn [split|full]
set -euo pipefail

OC="$HOME/.local/openconnect-9.21/sbin/openconnect"
USER_ID="YOUR_USERNAME"

[[ -x "$OC" ]] || { echo "OpenConnect 9.21 missing at $OC – see section 2." >&2; exit 1; }

case "${1:-split}" in
  split) GROUP="RWTH-VPN (Split Tunnel)" ;;
  full)  GROUP="RWTH-VPN (Full Tunnel)"  ;;
  *) echo "Usage: $0 [split|full]" >&2; exit 1 ;;
esac

echo "Connecting to RWTH VPN – $GROUP"
exec sudo "$OC" \
  --protocol=anyconnect \
  --authgroup="$GROUP" \
  --user="$USER_ID" \
  vpn.rwth-aachen.de
EOF
chmod +x ~/bin/rwth-vpn
```

Edit `USER_ID` in the script once. `~/bin` is in your PATH by default on Fedora (you may
need to log out and back in the first time), so afterwards this is enough:

```bash
rwth-vpn          # split tunnel
rwth-vpn full     # full tunnel
```

---

## 7. NetworkManager / GNOME click-to-connect — not currently possible

The obvious wish is an entry in the GNOME network menu via
`NetworkManager-openconnect`. That **does not work here**: the plugin links against the
system `libopenconnect` (9.12) and therefore hits exactly the STRAP bug from section 1.
No setting works around it.

Once your Fedora release ships OpenConnect ≥ 9.20, the click-to-connect route will start
working on its own. Until then: the terminal, or `~/bin/rwth-vpn`.

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `401 Unauthorized` + `Cookie was rejected by server` | The system OpenConnect 9.12 is being used. Use the full path to 9.21. See section 1. |
| `404 Not Found` / `Invalid host entry. Please re-enter.` | 9.12 only: the ASA won't serve the login form to OpenConnect's old User-Agent. Resolved in 9.21. |
| `Auth choice "..." not available` | Group name misspelled — `RWTH-VPN` with a hyphen, in quotes. |
| `Login failed.` then `Password:` again | Wrong password; OpenConnect simply asks again. The `Response:` prompt only appears once the password is correct. |
| `Wrong OTP.` | Code expired (30-second window). Wait for a fresh one. Check your phone's clock. |
| `XML response has no "auth" node` | Usually a stale, unanswered OTP challenge from a previous attempt. Wait a minute and retry. |
| `Failed to open tun device` | Started without `sudo`. |
| Connected, but DNS does not resolve | Check `resolvectl status tun0`; if needed pass `--script=/etc/vpnc/vpnc-script` explicitly. |
| Want a verbose log | Append `-v` or `--dump-http-traffic`. **Careful:** `--dump-http-traffic` prints your password to the terminal in plaintext. |

---

## Appendix A: How the group names were determined

The ASA's aggregate-auth endpoint returns the login form directly as XML:

```bash
curl -A "AnyConnect Linux_64 4.10.05085" \
     -H 'X-Transcend-Version: 1' -H 'X-Aggregate-Auth: 1' \
     -H 'Content-Type: application/xml; charset=utf-8' \
     --data-binary '<?xml version="1.0" encoding="UTF-8"?><config-auth client="vpn" type="init" aggregate-auth-version="2"><version who="vpn">4.10.05085</version><device-id>linux-64</device-id><group-access>https://vpn.rwth-aachen.de/</group-access></config-auth>' \
     https://vpn.rwth-aachen.de/
```

Response (abridged):

```xml
<opaque is-for="sg">
  <tunnel-group>TunnelGroup_RWTH_Full</tunnel-group>
  <group-alias>RWTH-VPN (Full Tunnel)</group-alias>
</opaque>
<auth id="main"><form>
  <input type="text" name="username" label="Username:"/>
  <input type="password" name="password" label="Password:"/>
  <select name="group_list" label="GROUP:">
    <option selected="true">RWTH-VPN (Full Tunnel)</option>
    <option>RWTH-VPN (Split Tunnel)</option>
  </select>
</form></auth>
```

Useful if the group names ever change — the current list always comes straight from the
server.

## Appendix B: Cisco Secure Client as a fallback

If the self-built client ever stops working, the official one remains. It is the less
convenient option:

- No Fedora package. Cisco ships a `.tgz` predeploy bundle; since release **5.1.15**
  webdeploy additionally produces an `.rpm` installable with `dnf install`. Cisco's GPG
  key must be imported first.
- The download is gated behind a Cisco service contract. In practice you obtain it
  through the RWTH software portal or the IT-Center.
- It installs a permanently running root daemon (`vpnagentd`) and occasionally needs
  reinstalling after kernel or glibc updates.

The project [gertoe/RWTH-VPN](https://github.com/gertoe/RWTH-VPN) automates exactly this
path — though it considers the openconnect approach dead, which is true for 9.12 but no
longer true for 9.21.

## Appendix C: Sources

- OpenConnect commit `94e0b16c` — RFC 9266 `tls-exporter` channel bindings for STRAP under TLS 1.3, shipped from v9.20
- [OpenConnect issue #659](https://gitlab.com/openconnect/openconnect/-/issues/659) — 401 on `/CSCOSSLC/tunnel`
- [OpenConnect issue #410](https://gitlab.com/openconnect/openconnect/-/issues/410) — "Cookie was rejected by server"
- [Cisco Secure Client 5.1 Admin Guide — Deployment](https://www.cisco.com/c/en/us/td/docs/security/vpn_client/anyconnect/Cisco-Secure-Client-5/admin/guide/b-cisco-secure-client-admin-guide-5-1/deploy-anyconnect.html)
