"use strict";

const fs = require("fs");
const path = require("path");
const config = require("../config");
const { FILES } = require("../constants");

function parseLines(raw, maxLines) {
  const lines = raw.split("\n");
  if (lines.length > 0 && lines[lines.length - 1] === "") {
    lines.pop();
  }
  if (lines.length > maxLines) {
    return lines.slice(lines.length - maxLines);
  }
  return lines;
}

function printLinePretty(line) {
  const trimmed = line.trim();
  if (!trimmed) return;
  try {
    const obj = JSON.parse(trimmed);
    // Pretty-print JSON notice
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(obj, null, 2));
  } catch {
    // Fallback to raw line
    // eslint-disable-next-line no-console
    console.log(line);
  }
  // eslint-disable-next-line no-console
  console.log();
}

function runLogsCommand(options) {
  const configDir = options.configDir || config.DEFAULT_CONFIG_DIR;
  const logPath = path.join(configDir, FILES.LOG);
  const maxLines =
    typeof options.lines === "number" && !Number.isNaN(options.lines)
      ? options.lines
      : parseInt(options.lines, 10);
  const linesToShow =
    Number.isFinite(maxLines) && maxLines > 0 ? maxLines : 50;

  if (!fs.existsSync(logPath)) {
    // eslint-disable-next-line no-console
    console.log(
      "No logs yet. Start a connection with 'psiphon-cli connect' first.",
    );
    return;
  }

  let fileSize = 0;
  try {
    const stat = fs.statSync(logPath);
    fileSize = stat.size;
  } catch {
    // eslint-disable-next-line no-console
    console.log(
      "Unable to read log file. Start a connection with 'psiphon-cli connect' first.",
    );
    return;
  }

  // Initial read: last N lines
  let lastPos = 0;
  if (fileSize > 0) {
    const chunkSize = 64 * 1024;
    const start = Math.max(0, fileSize - chunkSize);
    const fd = fs.openSync(logPath, "r");
    try {
      const length = fileSize - start;
      const buffer = Buffer.alloc(length);
      fs.readSync(fd, buffer, 0, length, start);
      const text = buffer.toString("utf-8");
      const lines = parseLines(text, linesToShow);
      for (const line of lines) {
        printLinePretty(line);
      }
    } finally {
      fs.closeSync(fd);
    }
    lastPos = fileSize;
  }

  // Follow mode
  let remainder = "";

  const interval = setInterval(() => {
    let stat;
    try {
      stat = fs.statSync(logPath);
    } catch {
      // If the file disappeared, just stop.
      clearInterval(interval);
      return;
    }

    // File truncated (new connect)
    if (stat.size < lastPos) {
      lastPos = 0;
      remainder = "";
    }

    if (stat.size === lastPos) {
      return;
    }

    const fd = fs.openSync(logPath, "r");
    try {
      const length = stat.size - lastPos;
      const buffer = Buffer.alloc(length);
      fs.readSync(fd, buffer, 0, length, lastPos);
      lastPos = stat.size;
      const chunk = buffer.toString("utf-8");
      const all = remainder + chunk;
      const parts = all.split("\n");
      remainder = parts.pop() || "";
      for (const line of parts) {
        printLinePretty(line);
      }
    } finally {
      fs.closeSync(fd);
    }
  }, 500);

  process.on("SIGINT", () => {
    clearInterval(interval);
    process.exit(0);
  });
}

module.exports = {
  runLogsCommand,
};

