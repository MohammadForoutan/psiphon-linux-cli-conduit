# Psiphon CLI

Unofficial Psiphon VPN client for **Linux and Windows** (CLI) and **Linux** (native GUI). Connect, disconnect, view stats, and inspect tunnel logs.

| Component | Platform | Description |
| --------- | -------- | ----------- |
| **CLI** | Linux, Windows | Terminal client — interactive or scripted |
| **GUI** | Linux | Native GTK4 / libadwaita desktop app ([`gui/`](gui/)) |

Both the CLI and GUI talk to **psiphon-tunnel-core** directly and share the same config directory (`~/.config/psiphon-cli` on Linux).

## Requirements

### CLI

- **Node.js** 18+ (not required for the standalone binary)
- **Psiphon tunnel core** binary for your platform from [psiphon-tunnel-core-binaries](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries). Place it in the project root (or use `--core <path>`):
  - **Linux:** `psiphon-tunnel-core-x86_64`
  - **Windows:** `psiphon-tunnel-core-windows-amd64.exe` (64-bit) or `psiphon-tunnel-core-i686.exe` (32-bit)

### GUI (Linux only)

- Vala, Meson, GTK4, libadwaita, json-glib, curl

Fedora:

```bash
sudo dnf install vala gcc meson gtk4-devel libadwaita-devel json-glib-devel curl
```

See [`gui/README.md`](gui/README.md) for build and run details.

## Install

```bash
git clone https://github.com/MohammadForoutan/psiphon-linux-cli-conduit.git
cd psiphon-linux-cli-conduit
npm install
```

Or install the CLI globally:

```bash
npm install -g .
# then run: psiphon-cli
```

## Usage (CLI)

### Connect (default)

```bash
npm start
# or
node cli/index.js connect
# or (if installed globally)
psiphon-cli
```

1. **Protocol:** choose **1** auto, **2** conduit, or **3** direct  
2. **Region:** choose **1** auto (Psiphon picks) or **2** and select a country (e.g. US, DE, NL)  
3. Tunnel starts. Proxies: **HTTP** `127.0.0.1:8081`, **SOCKS** `127.0.0.1:1081`  
4. Press **Ctrl+C** to disconnect

### Stats (live, updates every 2s)

In another terminal:

```bash
node cli/index.js stats
# or
psiphon-cli stats
```

Shows status, protocol, uptime, proxies, client/egress region, and traffic (↓/↑). Press **Ctrl+C** to exit.

### Disconnect

```bash
node cli/index.js disconnect
# or
psiphon-cli disconnect
```

## GUI (Linux)

Native desktop app in [`gui/`](gui/) — does **not** call the Node.js CLI. It spawns `psiphon-tunnel-core-x86_64` and uses the same config directory as the CLI.

**Features:**

- Large connect / disconnect control with connection status, public IP, and country flag
- Live stats panel (protocol, regions, traffic, uptime)
- Logs window (monospace, scrollable)
- Settings dialog (gear icon): protocol, region with flag icons, upstream proxy, core path, config directory, LAN mode, establish-tunnel timeout, refresh server list

**Quick start:**

```bash
cd gui
make setup    # first time only
make build
make run
```

Run `make help` in `gui/` for all targets (`install`, `clean`, `bundle`, etc.).

## Commands (CLI)

| Command                 | Description                                              |
| ----------------------- | -------------------------------------------------------- |
| `connect`               | Connect (choose protocol & region, run tunnel)           |
| `disconnect`            | Stop the tunnel                                          |
| `stats`                 | Show live stats (refreshes every 2 seconds)              |
| `logs`                  | Show live logs from tunnel core (pretty-printed JSON)     |
| `refresh-server-list`   | Download latest server list into config directory        |

## Options (global)

| Option              | Description                          |
| ------------------- | ------------------------------------ |
| `-c, --config-dir`  | Config directory (see below for defaults per OS) |
| `--core <path>`     | Path to the Psiphon tunnel core binary for your platform |

**Connect command** also supports:

| Option                    | Description |
| ------------------------- | ----------- |
| `-r, --region <code>`      | Egress region (ISO country code) |
| `-p, --upstream-proxy <url>` | Upstream proxy URL (see [Upstream proxy](#upstream-proxy)) |
| `--enable-timeout`         | Use psiphon-tunnel-core establish tunnel timeout (off by default; keeps retrying until connected) |
| `--enable-lan`             | Listen on all interfaces so HTTP/SOCKS proxies are reachable on the LAN (localhost only by default) |

**Default config directory:**

- Linux: `~/.config/psiphon-cli`
- Windows: `%LOCALAPPDATA%\psiphon-cli` (e.g. `C:\Users\<you>\AppData\Local\psiphon-cli`)

Example:

```bash
psiphon-cli -c ~/.config/psiphon connect
psiphon-cli --core /path/to/psiphon-tunnel-core-x86_64 connect -r DE
```

## Logs

You can view live logs from the Psiphon tunnel core while connected:

```bash
psiphon-cli logs
psiphon-cli logs -n 100   # show last 100 lines, then follow
```

Run this in another terminal after starting `psiphon-cli connect`. Logs are for the current session and are reset each time you start a new connection.

## Configuration

Configuration for the Psiphon core is driven by a JSON file named `psiphon.config`.

- This project ships with a default config at `configs/psiphon.config` that is based on the public free-network example from ProxySmart’s Psiphon Linux guide (it sets `RemoteServerListUrl`, `RemoteServerListSignaturePublicKey`, and related fields to use Psiphon’s official server list).[4](https://proxysmart.org/psiphon-setting-up-linux-client-with-free-servers/)
- On first run, that file is copied into your user config directory (see **Default config directory** above). A bundled snapshot of the official server list (`configs/server_list_compressed`) is also copied into the config directory as `remote_server_list`, matching `RemoteServerListDownloadFilename`.
- On each `connect`, the CLI updates only a few fields (region, protocol limits, traffic stats emission) and leaves the server list settings intact so that `psiphon-tunnel-core` can download and verify the official list of servers. When the remote URL is blocked, the core can still fall back to the cached `remote_server_list` file.

Advanced users can edit the `psiphon.config` in their config directory directly if they want to override server behavior (for example, using specific server tokens instead of the remote list). When `RemoteServerListUrl` and `RemoteServerListSignaturePublicKey` are removed, the CLI will warn that the official server list is not configured, but it will still respect your custom config.

You can manually refresh the cached server list when you have good connectivity:

```bash
psiphon-cli refresh-server-list
```

This downloads the latest list from `RemoteServerListUrl` into your config directory (overwriting the previous `remote_server_list`), which can then be used later in more restricted networks.

## Upstream proxy

All tunnel traffic can be routed through an upstream HTTP or SOCKS5 proxy. Use this when you are behind a corporate proxy or want to chain through another proxy.

- **Option:** `-p, --upstream-proxy <url>`
- **Environment:** `PSIPHON_UPSTREAM_PROXY` (used when the flag is not set; useful in scripts or containers)

Supported URL schemes: `http://`, `https://`, `socks5://`. Authentication can be included in the URL (e.g. `http://user:pass@proxy:8080`).

Examples:

```bash
psiphon-cli connect -p http://proxy.example.com:8080
psiphon-cli connect -p socks5://127.0.0.1:1080
PSIPHON_UPSTREAM_PROXY=socks5://proxy:1080 psiphon-cli connect
```

## Protocol modes

| Mode     | Description                              |
| -------- | ---------------------------------------- |
| **auto** | Let Psiphon choose (default)             |
| **conduit** | Via volunteer Conduit stations       |
| **direct**  | Direct to Psiphon servers            |

## Build

### Server list bundling

Before packaging, both CLI and GUI builds copy the cached server list from your machine into `configs/server_list_compressed` (from `~/.config/psiphon-cli/remote_server_list` by default). **No download is performed at build time.**

```bash
npm run bundle-server-list
```

Override with environment variables:

| Variable | Description |
| -------- | ----------- |
| `PSIPHON_SERVER_LIST` | Explicit path to a server list file |
| `PSIPHON_CONFIG_DIR` | Config directory to read `remote_server_list` from |

### CLI standalone binary

Build produces a standalone executable (no Node.js required). Place the matching core binary in the project root before building.

| Platform | Command             | Output                 |
| -------- | ------------------- | ---------------------- |
| Linux    | `npm run build`     | `dist/psiphon-cli`     |
| Windows  | `npm run build:win` | `dist/psiphon-cli.exe` |

On first run, the bundled core is extracted to the default config directory for your OS.

### GUI (Linux)

```bash
cd gui
make setup    # first time only
make build
make install  # optional, PREFIX=/usr/local by default
```

| Make target | Action |
| ----------- | ------ |
| `make help` | List all targets |
| `make build` | Configure (if needed) and compile |
| `make run` | Build and launch the app |
| `make bundle` | Copy local server list only |
| `make install` | Install to system prefix (use `DESTDIR` for staging) |
| `make package` | Create `../dist/psiphon-cli-gui-<version>-linux-x64.tar.gz` |
| `make clean` | Remove compiled objects |
| `make distclean` | Remove `build/` |

When run from the build tree, GSettings schemas in `build/data/` are loaded automatically.

**Release tarball:**

```bash
npm run build:gui
# → dist/psiphon-cli-gui-<version>-linux-x64.tar.gz
```

Install on another machine:

```bash
sudo tar xzf psiphon-cli-gui-*.tar.gz -C /
```

Requires GTK4, libadwaita, and `psiphon-tunnel-core-x86_64` on the target system.

### npm scripts

| Script | Output |
| ------ | ------ |
| `npm run bundle-server-list` | Copy local server list into `configs/server_list_compressed` |
| `npm run build` | `dist/psiphon-cli` |
| `npm run build:win` | `dist/psiphon-cli.exe` |
| `npm run build:gui` | `dist/psiphon-cli-gui-<version>-linux-x64.tar.gz` |
| `npm run package:gui` | Same as `build:gui` |
| `npm run build:all` | CLI binary + GUI tarball |

```bash
npm run build:all
```

## Documentation

- **GitHub Pages:** [`docs/index.html`](docs/index.html) — full CLI and GUI reference
- **GUI details:** [`gui/README.md`](gui/README.md)

To publish docs on GitHub Pages: **Settings → Pages → Deploy from branch → `/docs`**.

## Route whole system through tunnel

Use a system-wide proxy or a tool like [Karing](https://github.com/KaringX/karing): add SOCKS profile `socks://127.0.0.1:1081` and enable Tun / global routing.

## License

MIT
