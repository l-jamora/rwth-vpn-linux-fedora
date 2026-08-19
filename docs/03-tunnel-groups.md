# 3. The tunnel groups

> Where you see `~/.local/openconnect-9.21/sbin/openconnect` below, plain
> `openconnect` is fine if your system version is ≥ 9.20 — check with
> `openconnect --version`.

Cisco Secure Client shows a dropdown with two entries. The exact values for
`--authgroup`:

| Cisco dropdown | value for `--authgroup` | `rwth-vpn.sh --group` | internal tunnel group |
|---|---|---|---|
| Full Tunnel (all traffic via RWTH) | `RWTH-VPN (Full Tunnel)` | `full` | `TunnelGroup_RWTH_Full` |
| Split Tunnel (RWTH-internal addresses only) | `RWTH-VPN (Split Tunnel)` | `split` | — |

The hyphen in `RWTH-VPN`, the space and the parentheses are all part of the name — so
always quote it. Get it wrong and OpenConnect reports
`Auth choice "..." not available` and falls back to asking interactively. (`rwth-vpn.sh`
quotes it for you; you only pass `split` or `full`.)

Query the list yourself at any time:

```bash
./rwth-vpn.sh --groups
# or, directly:
~/.local/openconnect-9.21/sbin/openconnect --authenticate vpn.rwth-aachen.de
```

**Which one do you want?** Split Tunnel routes only RWTH-internal addresses through the
VPN — enough for university file servers, internal web services and licence servers,
and it keeps the rest of your traffic local and fast. Full Tunnel sends *all* traffic
through RWTH; you need it when a service checks that your public IP belongs to the
university, which is the usual case for licensed journals and e-book access.

If the names ever change server-side, [Appendix A](appendix.md#a-how-the-group-names-were-determined)
shows how they were determined in the first place.
