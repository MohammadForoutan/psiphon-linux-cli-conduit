#!/usr/bin/env bash
# Post-install helper: verify packaged default server list is present.
set -euo pipefail

datadir="${1:-/usr/share}"
list_dir="${datadir}/psiphon-cli-gui/configs"
bundled="${list_dir}/server_list_compressed"
default_list="${list_dir}/remote_server_list"

if [[ -f "$bundled" ]]; then
  chmod 644 "$bundled"
  if [[ ! -f "$default_list" ]]; then
    cp -f "$bundled" "$default_list"
  fi
fi
