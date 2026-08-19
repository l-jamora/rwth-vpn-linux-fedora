# 6. NetworkManager / GNOME click-to-connect

The obvious wish is an entry in the GNOME network menu via
`NetworkManager-openconnect`. Whether that works depends entirely on the
`libopenconnect` your distro ships, because the plugin links against it:

- **system OpenConnect ≥ 9.20** (Arch/CachyOS and friends): it works, and it is the
  nicest way to use the VPN. Set the gateway to `vpn.rwth-aachen.de`, protocol
  *Cisco AnyConnect*, and pick the tunnel group from the dropdown.
- **system OpenConnect 9.12** (Fedora 44 and other stable distros): it does **not**
  work — the plugin hits exactly the STRAP bug from
  [section 1](01-why-the-distro-package-fails.md), and no setting works around it. The
  self-built 9.21 in `~/.local` does not help either, since the plugin never loads it.
  Use the terminal, or `./rwth-vpn.sh`.
