#!/usr/bin/env bash
# docs/appendix.md (A) - Query the ASA's aggregate-auth endpoint directly to see the raw
# XML login form, including the current tunnel-group names/aliases.
set -euo pipefail

curl -A "AnyConnect Linux_64 4.10.05085" \
     -H 'X-Transcend-Version: 1' -H 'X-Aggregate-Auth: 1' \
     -H 'Content-Type: application/xml; charset=utf-8' \
     --data-binary '<?xml version="1.0" encoding="UTF-8"?><config-auth client="vpn" type="init" aggregate-auth-version="2"><version who="vpn">4.10.05085</version><device-id>linux-64</device-id><group-access>https://vpn.rwth-aachen.de/</group-access></config-auth>' \
     https://vpn.rwth-aachen.de/
