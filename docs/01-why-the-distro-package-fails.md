# 1. Why an old distro package fails

**Short version:** you need OpenConnect **≥ 9.20**. If your distro already ships it
(Arch/CachyOS, and increasingly everywhere else), nothing on this page applies — skip to
[03 — Tunnel groups](03-tunnel-groups.md).

With OpenConnect **9.12** — still what Fedora 44 and several other stable distros ship —
authentication completes cleanly (password accepted, 2FA code accepted) and then the
actual tunnel setup fails:

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
Cisco STRAP with TLSv1.3"*, shipped from **version 9.20** onwards.

Check what you have:

```bash
openconnect --version | head -n1
```

| Reports | What to do |
|---|---|
| v9.20 or newer | Nothing. `rwth-vpn.sh` uses your system binary as-is. |
| v9.12 or older | Build 9.21 into `~/.local` — [02](02-building-openconnect.md), or just run `./rwth-vpn.sh`, which offers to do it. |
| command not found | Install it from your package manager first; only build if the version is too old. |

Things that do **not** help with an old build (all tested): a different `--useragent`,
`--version-string`, `--os=win`, forcing IPv4, or the choice of tunnel group. All fail
identically with the same 401.

`rwth-vpn.sh` detects the system binary's version and only builds when it has to. See
[02 — Building OpenConnect 9.21](02-building-openconnect.md).
