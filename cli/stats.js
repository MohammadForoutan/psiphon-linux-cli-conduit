"use strict";

const fs = require("fs");
const path = require("path");
const { STATS_UPDATE_MS, FILES } = require("./constants");
const { formatBytes, formatBytesPerSec, formatUptime } = require("./format");

function getStatsPath(configDir) {
  return path.join(configDir, FILES.STATS);
}

function writeStatsFile(configDir, stats) {
  const statsPath = getStatsPath(configDir);
  try {
    fs.writeFileSync(statsPath, JSON.stringify(stats, null, 0), "utf-8");
  } catch (_) {}
}

function readStats(configDir) {
  const statsPath = getStatsPath(configDir);
  if (!fs.existsSync(statsPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(statsPath, "utf-8"));
  } catch (_) {
    return null;
  }
}

function printStatsFrame(configDir) {
  const stats = readStats(configDir);
  if (!stats) {
    console.log("Not connected. Run 'psiphon-cli connect' first.");
    return false;
  }
  const uptime =
    stats.uptimeMs != null ? formatUptime(stats.uptimeMs) : "-";
  process.stdout.write("\x1b[2J\x1b[H");
  console.log("--- Psiphon stats (refresh 2s) ---");
  console.log("  Status:      ", stats.status || "-");
  console.log("  Protocol:    ", stats.protocol || "-");
  console.log("  Tunnel:      ", stats.tunnelProtocol || "-");
  console.log("  Uptime:      ", uptime);
  console.log("  HTTP proxy:  ", stats.httpProxy || "-");
  console.log("  SOCKS proxy: ", stats.socksProxy || "-");
  console.log("  Client:      ", stats.clientRegion || "-");
  console.log("  Egress:      ", stats.egressRegion || "-");
  console.log(
    "  ↓ Down:      ",
    formatBytesPerSec(stats.downstreamBps || 0),
    "  total:",
    formatBytes(stats.totalDownBytes || 0),
  );
  console.log(
    "  ↑ Up:        ",
    formatBytesPerSec(stats.upstreamBps || 0),
    "  total:",
    formatBytes(stats.totalUpBytes || 0),
  );
  console.log(
    "  Regions:     ",
    stats.availableRegions || 0,
    "  ID:",
    stats.diagnosticID || "-",
  );
  console.log("-----------------------------------");
  return true;
}

function runStatsCommand(options) {
  const configDir = options.configDir || require("./config").DEFAULT_CONFIG_DIR;

  if (!printStatsFrame(configDir)) return;
  const interval = setInterval(() => {
    if (!printStatsFrame(configDir)) {
      clearInterval(interval);
      console.log("Tunnel disconnected.");
      process.exit(0);
    }
  }, STATS_UPDATE_MS);
  process.on("SIGINT", () => {
    clearInterval(interval);
    process.exit(0);
  });
}

module.exports = {
  getStatsPath,
  writeStatsFile,
  readStats,
  printStatsFrame,
  runStatsCommand,
  STATS_UPDATE_MS,
};
