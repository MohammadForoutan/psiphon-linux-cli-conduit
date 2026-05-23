#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUI="$ROOT/gui"
BUILD="$GUI/build"
DIST="$ROOT/dist"
STAGING="$DIST/psiphon-cli-gui-staging"
VERSION="$(node -p "require('$ROOT/package.json').version")"
ARCH="${ARCH:-x64}"
OUTPUT="$DIST/psiphon-cli-gui-${VERSION}-linux-${ARCH}.tar.gz"

read_prefix () {
  if [[ -d "$BUILD" ]]; then
    meson introspect "$BUILD" --get-option prefix 2>/dev/null || true
  fi
}

PREFIX="${PREFIX:-$(read_prefix)}"
PREFIX="${PREFIX:-/usr/local}"

mkdir -p "$DIST"
rm -rf "$STAGING"

cd "$GUI"
make build
DESTDIR="$STAGING" make install

SCHEMA_DIR="$STAGING$PREFIX/share/glib-2.0/schemas"
if [[ -d "$SCHEMA_DIR" ]]; then
  if command -v glib-compile-schemas >/dev/null 2>&1; then
    glib-compile-schemas "$SCHEMA_DIR"
  else
    echo "warning: glib-compile-schemas not found; tarball may need manual schema compile after install" >&2
  fi
fi

rm -f "$OUTPUT"
tar -C "$STAGING" -czf "$OUTPUT" .
rm -rf "$STAGING"

echo "Created $OUTPUT"
echo "Install: sudo tar xzf $(basename "$OUTPUT") -C /"
