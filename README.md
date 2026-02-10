# Psiphon Linux CLI

Unofficial Psiphon VPN client for Linux — a simple CLI to connect, disconnect, and view tunnel stats.

## Requirements

- **Node.js** 14+
- **Psiphon tunnel core** binary: [psiphon-tunnel-core-x86_64](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries) — place it in the project root (or use `--core <path>`)

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

## Options (global)

| Option              | Description                          |
| ------------------- | ------------------------------------ |
| `-c, --config-dir`  | Config directory (default: `~/.config/psiphon-cli`) |
| `--core <path>`     | Path to `psiphon-tunnel-core-x86_64`  |

Example:

```bash
psiphon-cli -c ~/.config/psiphon connect
psiphon-cli --core /path/to/psiphon-tunnel-core-x86_64 connect -r DE
```

## Protocol modes

| Mode     | Description                              |
| -------- | ---------------------------------------- |
| **auto** | Let Psiphon choose (default)             |
| **conduit** | Via volunteer Conduit stations       |
| **direct**  | Direct to Psiphon servers            |

## Build standalone binary

```bash
npm run build
```

Produces `dist/psiphon-cli` — standalone Linux x64 binary (no Node.js required). Config and core are bundled; on first run the core is extracted to `~/.config/psiphon-cli/`.

**Requires** `psiphon-tunnel-core-x86_64` in the project root. Get it from [Psiphon tunnel core binaries](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries) (Linux).

## Route whole system through tunnel

Use a system-wide proxy or a tool like [Karing](https://github.com/KaringX/karing): add SOCKS profile `socks://127.0.0.1:1081` and enable Tun / global routing.

## License

MIT
