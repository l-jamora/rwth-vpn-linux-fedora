# 4. Connecting

> Where you see `~/.local/openconnect-9.21/sbin/openconnect` below, plain
> `openconnect` is fine if your system version is ≥ 9.20 — check with
> `openconnect --version`.

Your username is the RWTH identifier you use for the VPN — for most people the
`ab123456` style RWTH Single Sign-On ID. Substitute it for `YOUR_USERNAME` below.

The short way is `./rwth-vpn.sh -u YOUR_USERNAME` (see the README). The manual
equivalent:

```bash
sudo ~/.local/openconnect-9.21/sbin/openconnect \
  --protocol=anyconnect \
  --authgroup="RWTH-VPN (Split Tunnel)" \
  --user=YOUR_USERNAME \
  vpn.rwth-aachen.de
```

Full tunnel: same command with `--authgroup="RWTH-VPN (Full Tunnel)"`.

No `--useragent` is needed. Version 9.20+ sends a default User-Agent the RWTH ASA
accepts. (With 9.12 that was not the case — see [troubleshooting](07-troubleshooting.md).)

Scripted: [`scripts/connect.sh`](../scripts/connect.sh).

## What happens

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

## Verify

`./rwth-vpn.sh --status` reports all of this at once. By hand, in a **second** terminal:

```bash
ip addr show tun0                 # an RWTH address in 172.21.x.x
resolvectl status tun0            # RWTH DNS servers
curl -s https://ifconfig.me       # full tunnel only: an RWTH public IP
```
