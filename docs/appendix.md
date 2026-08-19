# Appendix

- [A: How the group names were determined](#a-how-the-group-names-were-determined)
- [B: Cisco Secure Client as a fallback](#b-cisco-secure-client-as-a-fallback)
- [C: Sources](#c-sources)

---

## A: How the group names were determined

The ASA's aggregate-auth endpoint returns the login form directly as XML:

```bash
curl -A "AnyConnect Linux_64 4.10.05085" \
     -H 'X-Transcend-Version: 1' -H 'X-Aggregate-Auth: 1' \
     -H 'Content-Type: application/xml; charset=utf-8' \
     --data-binary '<?xml version="1.0" encoding="UTF-8"?><config-auth client="vpn" type="init" aggregate-auth-version="2"><version who="vpn">4.10.05085</version><device-id>linux-64</device-id><group-access>https://vpn.rwth-aachen.de/</group-access></config-auth>' \
     https://vpn.rwth-aachen.de/
```

Scripted: [`scripts/discover-groups.sh`](../scripts/discover-groups.sh).

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

---

## B: Cisco Secure Client as a fallback

If the self-built client ever stops working, the official one remains. It is the less
convenient option:

- No distro package. Cisco ships a `.tgz` predeploy bundle; since release **5.1.15**
  webdeploy additionally produces an `.rpm` (Cisco's GPG key must be imported first).
  Arch users have the `cisco-secure-client` AUR package, which repackages the same
  bundle.
- The download is gated behind a Cisco service contract. In practice you obtain it
  through the RWTH software portal or the IT-Center.
- It installs a permanently running root daemon (`vpnagentd`) and occasionally needs
  reinstalling after kernel or glibc updates.

The project [gertoe/RWTH-VPN](https://github.com/gertoe/RWTH-VPN) automates exactly this
path — though it considers the openconnect approach dead, which was true for 9.12 but is
not true from 9.20 onwards.

---

## C: Sources

- OpenConnect commit `94e0b16c` — RFC 9266 `tls-exporter` channel bindings for STRAP under TLS 1.3, shipped from v9.20
- [OpenConnect issue #659](https://gitlab.com/openconnect/openconnect/-/issues/659) — 401 on `/CSCOSSLC/tunnel`
- [OpenConnect issue #410](https://gitlab.com/openconnect/openconnect/-/issues/410) — "Cookie was rejected by server"
- [Cisco Secure Client 5.1 Admin Guide — Deployment](https://www.cisco.com/c/en/us/td/docs/security/vpn_client/anyconnect/Cisco-Secure-Client-5/admin/guide/b-cisco-secure-client-admin-guide-5-1/deploy-anyconnect.html)
