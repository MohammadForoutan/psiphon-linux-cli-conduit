# Psiphon CLI (source)

Modular CLI implementation. See the [project README](../README.md) for install, usage, and commands.

## Layout

- `index.js` — entry, Commander setup
- `constants.js` — protocols, paths, file names
- `config.js` — config dir, build config
- `regions.js` — region list, flag helper
- `format.js` — bytes & uptime formatting
- `stats.js` — stats file read/write, stats command
- `core.js` — core binary path, run tunnel
- `prompts.js` — protocol & region prompts
- `commands/` — connect, disconnect, stats
