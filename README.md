# Psiphon Linux

Unofficial Psiphon VPN client for Linux (CLI).

## Requirements

- Node.js
- [Psiphon tunnel core](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries/blob/master/linux/psiphon-tunnel-core-x86_64) binary — place `psiphon-tunnel-core-x86_64` in the project root

## Install

```bash
npm install
```

## Build

```bash
npm run build
```

Produces `dist/psiphon-cli` — standalone Linux x64 binary (~54MB, no Node.js needed). Core and configs are bundled; on first run the core is extracted to `~/.config/psiphon-cli/`.

**Build requires** `psiphon-tunnel-core-x86_64` in the project root. Download from [Psiphon tunnel core binaries](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries) (Linux folder).

## Usage

```bash
npm start
# or
node cli/index.js run
```

1. Choose protocol: **1** auto, **2** conduit, **3** direct
2. Tunnel starts — split TUI: **stats** (top) and **logs** (bottom)
3. Proxy: `127.0.0.1:8081` (HTTP), `127.0.0.1:1081` (SOCKS)
4. Press **q** to stop

Use `--no-tui` for plain output (e.g. when piping).

## Commands

| Command | Description               |
| ------- | ------------------------- |
| `run`   | Interactive run (default) |
| `run --no-tui` | Plain output, no split panel |
| `stop`  | Stop the tunnel           |

## Protocol modes

| Mode    | Description                            |
| ------- | -------------------------------------- |
| auto    | Use all available protocols            |
| conduit | Connect via volunteer Conduit Stations |
| direct  | Connect directly to Psiphon servers    |

## Tunnel whole system

Use [Karing](https://github.com/KaringX/karing) — add a SOCKS profile `socks://127.0.0.1:1081` and route all traffic through it (Tun Mode).

## License

MIT
