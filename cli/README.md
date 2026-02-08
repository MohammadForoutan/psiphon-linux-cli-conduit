# Psiphon CLI

Interactive CLI for running Psiphon tunnel core.

## Usage

```bash
npm start
# or
node cli/index.js run
```

**Flow:**
1. Choose protocol: auto (1), conduit (2), or direct (3)
2. Tunnel starts and prints logs
3. Press **q** to stop
4. Option to change settings and run again

## Commands

| Command | Description |
|---------|-------------|
| `run` | Interactive run (default) |
| `stop` | Stop the tunnel |

## Protocol modes

| Mode | Description |
|------|-------------|
| auto | Use all available protocols |
| conduit | Connect via volunteer Conduit Stations |
| direct | Connect directly to Psiphon servers |
