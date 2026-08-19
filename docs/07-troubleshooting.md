# 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `401 Unauthorized` + `Cookie was rejected by server` | An OpenConnect older than 9.20 is being used. Check `openconnect --version`; use the full path to the 9.21 build. See [section 1](01-why-the-distro-package-fails.md). |
| `404 Not Found` / `Invalid host entry. Please re-enter.` | Old versions only: the ASA won't serve the login form to OpenConnect's old User-Agent. Resolved in 9.20+. |
| `Auth choice "..." not available` | Group name misspelled — `RWTH-VPN` with a hyphen, in quotes. See [section 3](03-tunnel-groups.md). |
| `Login failed.` then `Password:` again | Wrong password; OpenConnect simply asks again. The `Response:` prompt only appears once the password is correct. |
| `Wrong OTP.` | Code expired (30-second window). Wait for a fresh one. Check your phone's clock. |
| `XML response has no "auth" node` | Usually a stale, unanswered OTP challenge from a previous attempt. Wait a minute and retry. |
| `Failed to open tun device` | Started without `sudo`. |
| Connected, but DNS does not resolve | Check `resolvectl status tun0`; if needed pass `--script=` explicitly with your distro's vpnc-script path (`/etc/vpnc/vpnc-script` on Fedora/Debian, `/usr/share/vpnc-scripts/vpnc-script` on Arch). |
| Want a verbose log | `./rwth-vpn.sh -v`, or append `-v` / `--dump-http-traffic` by hand. **Careful:** `--dump-http-traffic` prints your password to the terminal in plaintext. |
| `sudo: openconnect: command not found` / no package manager detected | `scripts/install-deps.sh` supports pacman, dnf, apt and zypper. On anything else, install the packages listed in `requirements.txt` by hand. |
| `rwth-vpn.sh` wants to rebuild every time | The build did not land in `~/.local/openconnect-9.21/sbin/openconnect`, or it reports a version below 9.20. Check with [`scripts/verify-openconnect.sh`](../scripts/verify-openconnect.sh). |
| Wrong username remembered | It is cached in `~/.config/rwth-vpn.conf`. Delete the file, or pass `-u` once to overwrite it. |
