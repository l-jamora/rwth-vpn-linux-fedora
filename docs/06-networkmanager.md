# 6. NetworkManager / GNOME click-to-connect — not currently possible

The obvious wish is an entry in the GNOME network menu via
`NetworkManager-openconnect`. That **does not work here**: the plugin links against the
system `libopenconnect` (9.12) and therefore hits exactly the STRAP bug from
[section 1](01-why-the-fedora-package-fails.md). No setting works around it.

Once your Fedora release ships OpenConnect ≥ 9.20, the click-to-connect route will start
working on its own. Until then: the terminal, or `./rwth-vpn.sh`.
