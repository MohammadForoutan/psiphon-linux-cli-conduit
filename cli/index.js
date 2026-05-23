#!/usr/bin/env node

"use strict";

const { parseCliArgs, printHelp, printVersion } = require("./argv");
const { runConnectCommand } = require("./commands/connect");
const { runDisconnectCommand } = require("./commands/disconnect");
const { runStatsCommand } = require("./commands/stats");
const { runLogsCommand } = require("./commands/logs");
const { runRefreshServerListCommand } = require("./commands/refresh-server-list");

let parsed;

try {
  parsed = parseCliArgs(process.argv);
} catch (err) {
  console.error(`Error: ${err.message}`);
  console.error("Run 'psiphon-cli --help' for usage.");
  process.exit(1);
}

const { command, options } = parsed;

if (options.help) {
  printHelp();
  process.exit(0);
}

if (options.version) {
  printVersion();
  process.exit(0);
}

switch (command) {
  case "connect":
    runConnectCommand(options);
    break;
  case "disconnect":
    runDisconnectCommand(options);
    break;
  case "stats":
    runStatsCommand(options);
    break;
  case "logs":
    if (typeof options.lines === "string") {
      const parsedLines = parseInt(options.lines, 10);
      if (!Number.isNaN(parsedLines)) {
        options.lines = parsedLines;
      }
    }
    runLogsCommand(options);
    break;
  case "refresh-server-list":
    runRefreshServerListCommand(options);
    break;
  default:
    console.error(`Error: unknown command '${command}'`);
    console.error("Run 'psiphon-cli --help' for usage.");
    process.exit(1);
}
