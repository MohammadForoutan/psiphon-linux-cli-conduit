#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
SPEC="$ROOT/packaging/rpm/psiphon-cli-gui.spec"
VERSION="$(node -p "require('$ROOT/package.json').version")"
NAME="psiphon-cli-gui"
CORE="$ROOT/psiphon-tunnel-core-x86_64"
SING_BOX="$ROOT/sing-box"
LIBCRONET="$ROOT/libcronet.so"
SERVER_LIST="$ROOT/configs/server_list_compressed"
SRCDIR="$DIST/rpm-src/$NAME-$VERSION"
SRCTARBALL="$DIST/$NAME-$VERSION.tar.gz"
RPMBUILD_ROOT="${RPMBUILD_ROOT:-$HOME/rpmbuild}"
OFFLINE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--offline]

Build the psiphon-cli-gui RPM.

  --offline   Do not download anything; require bundled assets in the repo root.

Bundled assets (offline / included in the source tarball):
  psiphon-tunnel-core-x86_64
  sing-box
  libcronet.so
  configs/server_list_compressed

Online-only prep (run once before --offline):
  npm run prepare:rpm
EOF
}

for arg in "$@"; do
  case "$arg" in
    --offline)
      OFFLINE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${PSIPHON_RPM_OFFLINE:-}" == "1" ]]; then
  OFFLINE=true
fi

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "error: rpmbuild is required (install rpm-build / rpmdevtools)" >&2
  exit 1
fi

require_file() {
  local path="$1"
  local hint="$2"
  if [[ ! -e "$path" ]]; then
    echo "error: required file missing: $path" >&2
    echo "hint: $hint" >&2
    exit 1
  fi
}

require_executable() {
  local path="$1"
  local hint="$2"
  require_file "$path" "$hint"
  if [[ ! -x "$path" ]]; then
    echo "error: file is not executable: $path" >&2
    echo "hint: chmod +x $path" >&2
    exit 1
  fi
}

ensure_server_list() {
  if [[ -f "$SERVER_LIST" ]] && [[ -s "$SERVER_LIST" ]]; then
    echo "Using bundled server list: configs/server_list_compressed"
    return
  fi

  if $OFFLINE; then
    require_file "$SERVER_LIST" "run 'npm run prepare:rpm' once online, or copy remote_server_list to configs/server_list_compressed"
  fi

  echo "Downloading official server list for RPM..."
  node "$ROOT/scripts/download-server-list.js"
  require_file "$SERVER_LIST" "server list download did not produce configs/server_list_compressed"
}

ensure_sing_box() {
  if [[ -x "$SING_BOX" ]] && [[ -f "$LIBCRONET" ]]; then
    echo "Using bundled sing-box: ./sing-box (+ libcronet.so)"
    return
  fi

  if $OFFLINE; then
    require_executable "$SING_BOX" "run 'npm run prepare:rpm' once online to fetch sing-box and libcronet.so"
    require_file "$LIBCRONET" "run 'npm run prepare:rpm' once online to fetch sing-box and libcronet.so"
  fi

  echo "Downloading sing-box for RPM..."
  node "$ROOT/scripts/download-sing-box.js"
  require_executable "$SING_BOX" "sing-box download failed"
  require_file "$LIBCRONET" "libcronet.so was not extracted next to sing-box"
}

require_executable "$CORE" "place an executable psiphon-tunnel-core-x86_64 in the repository root"

if $OFFLINE; then
  echo "Offline RPM build: using bundled assets only (no downloads)."
else
  echo "Online RPM build: refreshing missing bundled assets when needed."
fi

ensure_server_list
ensure_sing_box

export PSIPHON_SERVER_LIST="$SERVER_LIST"
node "$ROOT/scripts/bundle-server-list.js" --repo-only

mkdir -p "$DIST/rpm-src"
rm -rf "$SRCDIR"
mkdir -p "$SRCDIR"

copy_tree() {
  local src="$1"
  local dest="$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude node_modules --exclude dist --exclude gui/build --exclude '.git' "$src/" "$dest/"
  else
    tar -C "$src" \
      --exclude=node_modules \
      --exclude=dist \
      --exclude=gui/build \
      --exclude=.git \
      -cf - . | tar -C "$dest" -xf -
  fi
}

copy_tree "$ROOT" "$SRCDIR"
cp "$CORE" "$SRCDIR/psiphon-tunnel-core-x86_64"
cp "$SING_BOX" "$SRCDIR/sing-box"
cp "$LIBCRONET" "$SRCDIR/libcronet.so"
cp "$SERVER_LIST" "$SRCDIR/configs/server_list_compressed"

rm -f "$SRCTARBALL"
tar -C "$DIST/rpm-src" -czf "$SRCTARBALL" "$NAME-$VERSION"

mkdir -p "$RPMBUILD_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp "$SRCTARBALL" "$RPMBUILD_ROOT/SOURCES/"
cp "$SPEC" "$RPMBUILD_ROOT/SPECS/$NAME.spec"

rpmbuild -bb \
  --define "_topdir $RPMBUILD_ROOT" \
  --define "version $VERSION" \
  "$RPMBUILD_ROOT/SPECS/$NAME.spec"

mkdir -p "$DIST"
shopt -s nullglob
for rpm in "$RPMBUILD_ROOT/RPMS"/*/"$NAME"-*.rpm; do
  cp -f "$rpm" "$DIST/"
  echo "Created $DIST/$(basename "$rpm")"
done
shopt -u nullglob
