#!/usr/bin/env bash
# Post-install helper: ensure packaged sing-box and libcronet.so are executable.
set -euo pipefail

libdir="${1:-/usr/lib}"
bundle_dir="${libdir}/psiphon-cli-gui"
sing_box="${bundle_dir}/sing-box"
libcronet="${bundle_dir}/libcronet.so"

if [[ -f "$sing_box" ]]; then
  chmod 755 "$sing_box"
  if command -v setcap >/dev/null 2>&1; then
    setcap cap_net_admin+ep "$sing_box" 2>/dev/null || true
  fi
fi

if [[ -f "$libcronet" ]]; then
  chmod 755 "$libcronet"
fi
