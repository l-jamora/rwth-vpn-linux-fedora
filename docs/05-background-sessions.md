# 5. Running it in the background

> Where you see `~/.local/openconnect-9.21/sbin/openconnect` below, plain
> `openconnect` is fine if your system version is ≥ 9.20 — check with
> `openconnect --version`.

`./rwth-vpn.sh -u YOUR_USERNAME --background` does this; `./rwth-vpn.sh --disconnect`
ends it. The manual equivalent:

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

Scripted: [`scripts/connect-background.sh`](../scripts/connect-background.sh) and
[`scripts/disconnect.sh`](../scripts/disconnect.sh).
