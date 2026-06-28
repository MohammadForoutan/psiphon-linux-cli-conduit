# Psiphon CLI GUI

Native Linux GUI for Psiphon CLI, implemented in Vala with GTK4 and libadwaita.

This app does not call the Node.js CLI. It manages `psiphon-tunnel-core-x86_64`
directly and shares the same config directory as the CLI:

```text
~/.config/psiphon-cli
```

## Requirements

Fedora:

```bash
sudo dnf install vala gcc meson gtk4-devel libadwaita-devel json-glib-devel curl
```

You also need `psiphon-tunnel-core-x86_64`. Put it in the repository root during
development, install it on your `PATH`, or set a custom path with GSettings.

## Build

```bash
cd gui
make setup    # first time only
make build
make run
```

Or with Meson directly:

```bash
cd gui
meson setup build
meson compile -C build
./build/psiphon-cli-gui
```

`make help` lists all targets (`build`, `run`, `install`, `clean`, `bundle`, etc.).

Before compile, the build copies the Psiphon server list from your machine
(typically `~/.config/psiphon-cli/remote_server_list`) into `configs/server_list_compressed`
for bundling. No download is performed. Override with `PSIPHON_SERVER_LIST` or
`PSIPHON_CONFIG_DIR` if needed.

From the repository root you can build CLI and GUI together:

```bash
npm run build:all
```

**Release tarball** (publish on GitHub Releases):

```bash
npm run build:gui
# or: make package
```

Creates `dist/psiphon-cli-gui-<version>-linux-x64.tar.gz` and optionally an `.AppImage`. Run without installing:

```bash
tar xzf psiphon-cli-gui-*.tar.gz
./psiphon-cli-gui-portable/run
```

Do **not** run `./usr/local/bin/psiphon-cli-gui` directly after extract — use the `run` launcher so GSettings and library paths are set correctly.

The build output includes compiled GSettings schemas in `build/data/`. The app
loads them automatically when run from the build tree; after `meson install`, the
system schema path is used instead.

## RPM package (Fedora/RHEL)

Place `psiphon-tunnel-core-x86_64` in the repository root, then:

```bash
cd gui
make rpm
# or from repo root:
npm run build:gui:rpm
```

The RPM build **downloads** the official server list from `RemoteServerListUrl` in `configs/psiphon.config` before packaging. After install:

- Packaged lists live under `/usr/share/psiphon-cli-gui/configs/` as `server_list_compressed` and `remote_server_list`
- On first GUI launch, `~/.config/psiphon-cli/remote_server_list` is created from the packaged default if missing

The RPM also installs the GUI to `/usr`, ships the tunnel core under `/usr/lib64/psiphon-cli-gui/` (or `/usr/lib/` on 32-bit), and sets the default `core-path` GSettings key to that location.

Build requirements: `rpm-build`, `meson`, `vala`, `gtk4-devel`, `libadwaita-devel`, `json-glib-devel`, `nodejs`.

## Custom Core Path

After installing the GSettings schema, you can set a custom core path:

```bash
gsettings set io.github.MohammadForoutan.PsiphonCliGui core-path '/path/to/psiphon-tunnel-core-x86_64'
```

On RPM installs, the default is `/usr/lib64/psiphon-cli-gui/psiphon-tunnel-core-x86_64` (via GSettings override).
