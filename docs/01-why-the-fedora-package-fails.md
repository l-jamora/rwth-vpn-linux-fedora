# 1. Why the Fedora package fails

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

Once your Fedora release ships OpenConnect ≥ 9.20, none of this applies any more:
`rwth-vpn.sh` detects the system binary's version and uses it instead of building
anything. See [02 — Building OpenConnect 9.21](02-building-openconnect.md).
