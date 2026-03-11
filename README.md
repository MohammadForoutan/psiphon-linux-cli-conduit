# Psiphon CLI

Unofficial Psiphon VPN client — CLI for Linux and Windows to connect, disconnect, and view tunnel stats.

## Requirements

- **Node.js** 14+
- **Psiphon tunnel core** binary for your platform from [psiphon-tunnel-core-binaries](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries). Place it in the project root (or use `--core <path>`):
  - **Linux:** `psiphon-tunnel-core-x86_64` (in `linux/`)
  - **Windows:** `psiphon-tunnel-core-windows-amd64.exe` (64-bit) or `psiphon-tunnel-core-i686.exe` (32-bit) in `windows/`

## Install

```bash
git clone https://github.com/your-username/psiphon-linux-cli-conduit.git
cd psiphon-linux-cli-conduit
npm install
```

Or install globally:

```bash
npm install -g .
# then run: psiphon-cli
```

## Usage

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

## Commands

| Command       | Description                                      |
| ------------- | ------------------------------------------------ |
| `connect`     | Connect (choose protocol & region, run tunnel)  |
| `disconnect`  | Stop the tunnel                                  |
| `stats`       | Show live stats (refreshes every 2 seconds)      |
| `logs`        | Show live logs from tunnel core (pretty-printed JSON) |

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

## Build standalone binary

Build produces a standalone executable (no Node.js required). Place the matching core binary in the project root before building.

| Platform | Command           | Output               | Core binary in project root |
| -------- | ----------------- | -------------------- | ---------------------------- |
| Linux    | `npm run build`   | `dist/psiphon-cli`   | `psiphon-tunnel-core-x86_64` |
| Windows  | `npm run build:win` | `dist/psiphon-cli.exe` | `psiphon-tunnel-core-windows-amd64.exe` or `psiphon-tunnel-core-i686.exe` |

On first run, the bundled core is extracted to the default config directory for your OS.

## Route whole system through tunnel

Use a system-wide proxy or a tool like [Karing](https://github.com/KaringX/karing): add SOCKS profile `socks://127.0.0.1:1081` and enable Tun / global routing.

## License

MIT
