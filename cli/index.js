#!/usr/bin/env node

"use strict";

const { program } = require("commander");
const config = require("./config");
const { runConnectCommand } = require("./commands/connect");
const { runDisconnectCommand } = require("./commands/disconnect");
const { runStatsCommand } = require("./commands/stats");

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

program.parse();
