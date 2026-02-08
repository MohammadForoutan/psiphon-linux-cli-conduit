# Psiphon Linux

Unofficial Psiphon VPN client for Linux (CLI).

## Requirements

- Node.js
- [Psiphon tunnel core](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries/blob/master/linux/psiphon-tunnel-core-x86_64) binary — place `psiphon-tunnel-core-x86_64` in the project root

## Install

```bash
npm install
```

## Usage

```bash
npm start
# or
node cli/index.js run
```

1. Choose protocol: **1** auto, **2** conduit, **3** direct
2. Tunnel starts — proxy: `127.0.0.1:8081` (HTTP), `127.0.0.1:1081` (SOCKS)
3. Press **q** to stop

## Commands

| Command | Description               |
| ------- | ------------------------- |
| `run`   | Interactive run (default) |
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
