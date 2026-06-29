#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUI="$ROOT/gui"
BUILD="$GUI/build"
DIST="$ROOT/dist"
TOOLS="$DIST/.tools"
APPDIR="$DIST/psiphon-cli-gui-portable"
VERSION="$(node -p "require('$ROOT/package.json').version")"
ARCH="${ARCH:-x64}"
TARBALL="$DIST/psiphon-cli-gui-${VERSION}-linux-${ARCH}.tar.gz"
APPIMAGE="$DIST/psiphon-cli-gui-${VERSION}-linux-${ARCH}.AppImage"

read_prefix () {
  if [[ -d "$BUILD" ]]; then
    meson introspect "$BUILD" --get-option prefix 2>/dev/null || true
  fi
}

PREFIX="${PREFIX:-$(read_prefix)}"
PREFIX="${PREFIX:-/usr/local}"

ensure_tool () {
  local name="$1"
  local url="$2"
  local dest="$TOOLS/$name"
  if [[ -x "$dest" ]]; then
    printf '%s' "$dest"
    return 0
  fi
  mkdir -p "$TOOLS"
  echo "Downloading $name..."
  if ! curl -fsSL -o "$dest" "$url"; then
    rm -f "$dest"
    return 1
  fi
  chmod +x "$dest"
  printf '%s' "$dest"
}

mkdir -p "$DIST"
rm -rf "$APPDIR"

if [[ ! -x "$ROOT/sing-box" ]]; then
  echo "Downloading sing-box for portable bundle..."
  node "$ROOT/scripts/download-sing-box.js"
fi

cd "$GUI"
make build
DESTDIR="$APPDIR" make install

SCHEMA_DIR="$APPDIR$PREFIX/share/glib-2.0/schemas"
if [[ -d "$SCHEMA_DIR" ]]; then
  glib-compile-schemas "$SCHEMA_DIR"
  mkdir -p "$APPDIR$PREFIX/bin/data"
  cp "$SCHEMA_DIR/gschemas.compiled" "$APPDIR$PREFIX/bin/data/gschemas.compiled"
fi

DESKTOP_FILE="$APPDIR$PREFIX/share/applications/io.github.MohammadForoutan.PsiphonCliGui.desktop"
EXECUTABLE="$APPDIR$PREFIX/bin/psiphon-cli-gui"

if [[ -x "$ROOT/psiphon-tunnel-core-x86_64" ]]; then
  cp "$ROOT/psiphon-tunnel-core-x86_64" "$APPDIR$PREFIX/bin/"
fi

if [[ -x "$ROOT/sing-box" ]]; then
  mkdir -p "$APPDIR$PREFIX/lib/psiphon-cli-gui"
  cp "$ROOT/sing-box" "$APPDIR$PREFIX/lib/psiphon-cli-gui/"
  if [[ -f "$ROOT/libcronet.so" ]]; then
    cp "$ROOT/libcronet.so" "$APPDIR$PREFIX/lib/psiphon-cli-gui/"
  fi
fi

if [[ -f "$DESKTOP_FILE" && -x "$EXECUTABLE" ]]; then
  if LINUXDEPLOY="$(ensure_tool linuxdeploy-x86_64.AppImage \
      "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage")" && \
     LINUXDEPLOY_PLUGIN_GTK="$(ensure_tool linuxdeploy-plugin-gtk-x86_64.AppImage \
      "https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/releases/download/continuous/linuxdeploy-plugin-gtk-x86_64.AppImage")"; then
    export LINUXDEPLOY_PLUGIN_GTK
    export DEPLOY_GTK_IM_MODULE="${DEPLOY_GTK_IM_MODULE:-none}"

    if ! "$LINUXDEPLOY" \
      --appdir="$APPDIR" \
      --executable="$EXECUTABLE" \
      --desktop-file="$DESKTOP_FILE" \
      --plugin gtk; then
      echo "warning: library bundling failed; tarball will still run on systems with GTK4/libadwaita installed" >&2
    fi

    rm -f "$APPIMAGE"
    if "$LINUXDEPLOY" --appdir="$APPDIR" --output appimage; then
      shopt -s nullglob
      for candidate in "$DIST"/*.AppImage "$ROOT"/*.AppImage; do
        if [[ -f "$candidate" ]]; then
          mv "$candidate" "$APPIMAGE"
          break
        fi
      done
      shopt -u nullglob
    fi
  else
    echo "warning: could not download linuxdeploy; tarball is portable but requires GTK4/libadwaita on the system" >&2
  fi
fi

cat > "$APPDIR/run" <<RUN
#!/usr/bin/env bash
set -euo pipefail
ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PREFIX="\$ROOT${PREFIX}"
BIN="\$PREFIX/bin/psiphon-cli-gui"
SCHEMA="\$PREFIX/share/glib-2.0/schemas"
DATA="\$PREFIX/bin/data"

if [[ -f "\$SCHEMA/gschemas.compiled" ]]; then
  export GSETTINGS_SCHEMA_DIR="\$SCHEMA"
elif [[ -f "\$DATA/gschemas.compiled" ]]; then
  export GSETTINGS_SCHEMA_DIR="\$DATA"
fi

for libdir in "\$PREFIX/lib" "\$PREFIX/lib/x86_64-linux-gnu" "\$ROOT/lib" "\$ROOT/lib/x86_64-linux-gnu"; do
  if [[ -d "\$libdir" ]]; then
    export LD_LIBRARY_PATH="\${libdir}\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
  fi
done

exec "\$BIN" "\$@"
RUN
chmod +x "$APPDIR/run"

rm -f "$TARBALL"
tar -C "$DIST" -czf "$TARBALL" "$(basename "$APPDIR")"

echo "Created $TARBALL"
echo "Run: tar xzf $(basename "$TARBALL") && ./psiphon-cli-gui-portable/run"
if [[ -f "$APPIMAGE" ]]; then
  echo "Created $APPIMAGE"
fi
