#!/usr/bin/env bash
# Post-install helper: ensure packaged psiphon-tunnel-core is executable.
set -euo pipefail

libdir="${1:-/usr/lib}"
core="${libdir}/psiphon-cli-gui/psiphon-tunnel-core-x86_64"

if [[ -f "$core" ]]; then
  chmod 755 "$core"
fi
