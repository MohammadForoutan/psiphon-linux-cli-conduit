#!/usr/bin/env node

"use strict";

const { program } = require("commander");
const config = require("./config");
const { runConnectCommand } = require("./commands/connect");
const { runDisconnectCommand } = require("./commands/disconnect");
const { runStatsCommand } = require("./commands/stats");
const { runLogsCommand } = require("./commands/logs");

program
  .name("psiphon-cli")
  .description("Psiphon tunnel CLI: connect, disconnect, stats")
  .version("1.0.0")
  .option("-c, --config-dir <dir>", "config directory", config.DEFAULT_CONFIG_DIR)
  .option(
    "--core <path>",
    "path to psiphon-tunnel-core binary",
    require("./core").getCorePath(),
  );

program
  .command("connect", { isDefault: true })
  .description("Connect (choose protocol & region, then run tunnel)")
  .option("-r, --region <code>", "egress region (ISO country code)", "")
  .option(
    "-p, --upstream-proxy <url>",
    "upstream proxy URL (e.g. http://proxy:8080 or socks5://127.0.0.1:1080)",
    process.env.PSIPHON_UPSTREAM_PROXY || "",
  )
  .action((options) => {
    const globalOpts = program.opts();
    runConnectCommand({ ...globalOpts, ...options });
  });

program
  .command("disconnect")
  .description("Disconnect the tunnel")
  .action((options) => {
    const globalOpts = program.opts();
    runDisconnectCommand({ ...globalOpts, ...options });
  });

program
  .command("stats")
  .description("Show tunnel stats (updates every 2s)")
  .action((options) => {
    const globalOpts = program.opts();
    runStatsCommand({ ...globalOpts, ...options });
  });

program
  .command("logs")
  .description("Show live logs from psiphon-tunnel-core (pretty-printed JSON)")
  .option(
    "-n, --lines <number>",
    "number of recent log lines to show initially",
    "50",
  )
  .action((options) => {
    const globalOpts = program.opts();
    const merged = { ...globalOpts, ...options };
    if (typeof merged.lines === "string") {
      const parsed = parseInt(merged.lines, 10);
      if (!Number.isNaN(parsed)) {
        merged.lines = parsed;
      }
    }
    runLogsCommand(merged);
  });

program.parse();
