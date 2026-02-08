#!/usr/bin/env node

const { program } = require("commander");
const fs = require("fs");
const path = require("path");
const os = require("os");
const readline = require("readline");
const { spawn } = require("child_process");
const blessed = require("blessed");

const DIRECT_PROTOCOLS = [
  "SSH",
  "OSSH",
  "TLS-OSSH",
  "UNFRONTED-MEEK-OSSH",
  "UNFRONTED-MEEK-HTTPS-OSSH",
  "UNFRONTED-MEEK-SESSION-TICKET-OSSH",
  "FRONTED-MEEK-OSSH",
  "FRONTED-MEEK-HTTP-OSSH",
  "QUIC-OSSH",
  "FRONTED-MEEK-QUIC-OSSH",
  "TAPDANCE-OSSH",
  "CONJURE-OSSH",
  "SHADOWSOCKS-OSSH",
];
const CONDUIT_PROTOCOLS = [
  "INPROXY-WEBRTC-SSH",
  "INPROXY-WEBRTC-OSSH",
  "INPROXY-WEBRTC-TLS-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
  "INPROXY-WEBRTC-QUIC-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-QUIC-OSSH",
  "INPROXY-WEBRTC-SHADOWSOCKS-OSSH",
];

const PSIPHON_BIN = "psiphon-tunnel-core-x86_64";
const DEFAULT_CONFIG_DIR = path.join(os.homedir(), ".config", "psiphon-cli");

function getProjectRoot() {
  if (process.pkg) {
    return path.dirname(process.execPath);
  }
  return path.join(__dirname, "..");
}

function getCorePath() {
  const nextToBinary = path.join(path.dirname(process.execPath), PSIPHON_BIN);
  if (process.pkg) {
    if (fs.existsSync(nextToBinary)) {
      return nextToBinary;
    }
    const bundledPath = path.join(__dirname, "..", PSIPHON_BIN);
    if (fs.existsSync(bundledPath)) {
      const extractedPath = path.join(DEFAULT_CONFIG_DIR, PSIPHON_BIN);
      ensureConfigDir(DEFAULT_CONFIG_DIR);
      if (!fs.existsSync(extractedPath)) {
        fs.copyFileSync(bundledPath, extractedPath);
        fs.chmodSync(extractedPath, 0o755);
      }
      return extractedPath;
    }
  }
  return path.join(getProjectRoot(), PSIPHON_BIN);
}

const DEFAULT_CORE_PATH = getCorePath();

function getDefaultConfigPath() {
  return path.join(__dirname, "..", "configs", "psiphon.config");
}

function ensureConfigDir(configDir) {
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }
}

function getOrCreateConfig(configDir) {
  const userConfigPath = path.join(configDir, "psiphon.config");
  if (fs.existsSync(userConfigPath)) {
    return JSON.parse(fs.readFileSync(userConfigPath, "utf-8"));
  }
  const defaultConfigPath = getDefaultConfigPath();
  if (!fs.existsSync(defaultConfigPath)) {
    throw new Error(`Default config not found at ${defaultConfigPath}`);
  }
  const config = JSON.parse(fs.readFileSync(defaultConfigPath, "utf-8"));
  fs.writeFileSync(userConfigPath, JSON.stringify(config, null, 2), "utf-8");
  return config;
}

function buildConfig(configDir, options) {
  const config = getOrCreateConfig(configDir);
  config.EgressRegion = options.region || "";
  config.EmitBytesTransferred = true;

  if (options.protocol === "conduit") {
    config.LimitTunnelProtocols = CONDUIT_PROTOCOLS;
  } else if (options.protocol === "direct") {
    config.LimitTunnelProtocols = DIRECT_PROTOCOLS;
  } else {
    delete config.LimitTunnelProtocols;
  }

  const configPath = path.join(configDir, "psiphon.config");
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf-8");
  return configPath;
}

function promptProtocol(rl) {
  return new Promise((resolve) => {
    console.log("\n  Connection protocol:");
    console.log("    1) auto    - Let Psiphon choose (default)");
    console.log("    2) conduit - Via volunteer stations");
    console.log("    3) direct  - To Psiphon servers");
    rl.question("\n  Select (1/2/3): ", (answer) => {
      const trimmed = (answer || "1").trim().toLowerCase();
      if (trimmed === "2" || trimmed === "conduit") {
        resolve("conduit");
      } else if (trimmed === "3" || trimmed === "direct") {
        resolve("direct");
      } else {
        resolve("auto");
      }
    });
  });
}

function promptRunAgain(rl) {
  return new Promise((resolve) => {
    rl.question("\n  Change settings and run again? (y/n): ", (answer) => {
      resolve(
        (answer || "n").trim().toLowerCase() === "y" ||
          (answer || "n").trim().toLowerCase() === "yes",
      );
    });
  });
}

function formatBytesPerSec(bps) {
  if (bps >= 1024 * 1024) return (bps / 1024 / 1024).toFixed(2) + " MB/s";
  if (bps >= 1024) return (bps / 1024).toFixed(2) + " KB/s";
  return bps + " B/s";
}

function formatBytes(bytes) {
  if (bytes >= 1024 * 1024 * 1024) return (bytes / 1024 / 1024 / 1024).toFixed(2) + " GB";
  if (bytes >= 1024 * 1024) return (bytes / 1024 / 1024).toFixed(2) + " MB";
  if (bytes >= 1024) return (bytes / 1024).toFixed(2) + " KB";
  return bytes + " B";
}

function runTunnel(configDir, corePath, protocol, options = {}) {
  return new Promise((resolve) => {
    const useTUI = process.stdout.isTTY && !options.noTui;

    if (!useTUI) {
      return runTunnelPlain(configDir, corePath, protocol, resolve);
    }

    const tunnelStartTime = Date.now();
    const stats = {
      protocol,
      status: "connecting",
      httpProxy: "127.0.0.1:8081",
      socksProxy: "127.0.0.1:1081",
      tunnelCount: 0,
      clientRegion: "-",
      egressRegion: "-",
      downstreamBps: 0,
      upstreamBps: 0,
      totalDownBytes: 0,
      totalUpBytes: 0,
      diagnosticID: "-",
      tunnelProtocol: "-",
      availableRegions: 0,
    };
    let lastBytesTime = 0;

    let stdoutBuf = "";
    let stderrBuf = "";
    const logLines = [];
    const MAX_LOG_LINES = 200;

    function processLine(line, source) {
      if (!line.trim()) return;
      const displayLine = source === "stderr" ? "[stderr] " + line : line;
      try {
        const notice = JSON.parse(line);
        const { noticeType, data = {} } = notice;

        if (noticeType === "ListeningSocksProxyPort")
          stats.socksProxy = `127.0.0.1:${data.port}`;
        if (noticeType === "ListeningHttpProxyPort")
          stats.httpProxy = `127.0.0.1:${data.port}`;
        if (noticeType === "Tunnels") {
          stats.tunnelCount = data.count || 0;
          stats.status =
            stats.tunnelCount > 0 ? "connected" : stats.status === "connected" ? "disconnecting" : "connecting";
        }
        if (noticeType === "ClientRegion") stats.clientRegion = data.region || "-";
        if (noticeType === "ConnectedServerRegion")
          stats.egressRegion = data.serverRegion || "-";
        if (noticeType === "TrafficRateLimits") {
          stats.downstreamBps = data.downstreamBytesPerSecond || 0;
          stats.upstreamBps = data.upstreamBytesPerSecond || 0;
        }
        if (noticeType === "BytesTransferred") {
          const received = data.received || 0;
          const sent = data.sent || 0;
          stats.totalDownBytes += received;
          stats.totalUpBytes += sent;
          const now = Date.now();
          if (lastBytesTime > 0) {
            const elapsedSec = (now - lastBytesTime) / 1000;
            if (elapsedSec > 0) {
              stats.downstreamBps = Math.round(received / elapsedSec);
              stats.upstreamBps = Math.round(sent / elapsedSec);
            }
          }
          lastBytesTime = now;
        }
        if (noticeType === "TotalBytesTransferred") {
          stats.totalDownBytes = data.received || stats.totalDownBytes;
          stats.totalUpBytes = data.sent || stats.totalUpBytes;
        }
        if (noticeType === "ActiveTunnel") stats.tunnelProtocol = data.protocol || "-";
        if (noticeType === "AvailableEgressRegions")
          stats.availableRegions = (data.regions || []).length;
        if (noticeType === "ServerTimestamp")
          stats.diagnosticID = data.diagnosticID || "-";
        if (noticeType === "Exiting") stats.status = "exiting";
      } catch (_) {}
      addLog(displayLine);
    }

    function processStream(str, buf, source) {
      buf += str;
      const lines = buf.split("\n");
      const remaining = lines.pop() || "";
      for (const line of lines) processLine(line, source);
      return remaining;
    }

    const screen = blessed.screen({
      smartCSR: true,
      title: "Psiphon",
      cursor: { artificial: true, shape: "line", blink: true },
    });

    const statsBox = blessed.box({
      top: 0,
      left: 0,
      width: "100%",
      height: 11,
      border: { type: "line", fg: "cyan" },
      style: {
        border: { fg: "cyan" },
        fg: "white",
      },
      tags: true,
    });

    const logBox = blessed.box({
      top: 11,
      left: 0,
      width: "100%",
      height: "100%-11",
      border: { type: "line", fg: "gray" },
      style: {
        border: { fg: "gray" },
        fg: "green",
      },
      tags: true,
    });

    function formatUptime(ms) {
      const s = Math.floor(ms / 1000);
      const m = Math.floor(s / 60);
      const h = Math.floor(m / 60);
      if (h > 0) return `${h}h ${m % 60}m`;
      if (m > 0) return `${m}m ${s % 60}s`;
      return `${s}s`;
    }

    function renderStats() {
      const statusColor =
        stats.status === "connected"
          ? "{green-fg}"
          : stats.status === "connecting"
            ? "{yellow-fg}"
            : "{red-fg}";
      const uptime = formatUptime(Date.now() - tunnelStartTime);
      statsBox.setContent(
        `{bold}Psiphon - ${protocol}{/bold}  ` +
          `{cyan-fg}Uptime:{/cyan-fg} ${uptime}\n` +
          `{cyan-fg}Status:{/cyan-fg} ${statusColor}${stats.status}{/}  ` +
          `{cyan-fg}Tunnels:{/cyan-fg} ${stats.tunnelCount}  ` +
          `{cyan-fg}Protocol:{/cyan-fg} ${stats.tunnelProtocol}\n` +
          `{cyan-fg}Proxies:{/cyan-fg} HTTP ${stats.httpProxy}  SOCKS ${stats.socksProxy}\n` +
          `{cyan-fg}Client:{/cyan-fg} ${stats.clientRegion}  ` +
          `{cyan-fg}Egress:{/cyan-fg} ${stats.egressRegion}  ` +
          `{cyan-fg}Regions:{/cyan-fg} ${stats.availableRegions}  ` +
          `{cyan-fg}ID:{/cyan-fg} ${stats.diagnosticID}\n` +
          `{cyan-fg}↓ Down:{/cyan-fg} ${formatBytesPerSec(stats.downstreamBps)}  ` +
          `total: ${formatBytes(stats.totalDownBytes)}\n` +
          `{cyan-fg}↑ Up:{/cyan-fg}   ${formatBytesPerSec(stats.upstreamBps)}  ` +
          `total: ${formatBytes(stats.totalUpBytes)}\n` +
          `{gray-fg}Press q to stop{/gray-fg}`,
      );
      screen.render();
    }

    function addLog(line) {
      const short = line.length > 200 ? line.slice(0, 197) + "..." : line;
      logLines.push(short);
      if (logLines.length > MAX_LOG_LINES) logLines.shift();
      logBox.setContent(logLines.slice(-80).join("\n"));
      renderStats();
    }

    const child = spawn(corePath, ["-config", "psiphon.config"], {
      cwd: configDir,
      stdio: ["ignore", "pipe", "pipe"],
    });

    child.stdout.on("data", (data) => {
      stdoutBuf = processStream(data.toString(), stdoutBuf, "stdout");
    });

    child.stderr.on("data", (data) => {
      stderrBuf = processStream(data.toString(), stderrBuf, "stderr");
    });

    screen.append(statsBox);
    screen.append(logBox);
    renderStats();

    const REFRESH_MS = 500;
    const refreshInterval = setInterval(() => {
      if (stats.tunnelCount > 0 && lastBytesTime === 0) {
        stats.totalDownBytes += Math.round(stats.downstreamBps * (REFRESH_MS / 1000));
        stats.totalUpBytes += Math.round(stats.upstreamBps * (REFRESH_MS / 1000));
      }
      renderStats();
    }, REFRESH_MS);

    const onKey = (ch, key) => {
      if (ch === "q" || ch === "Q" || key.name === "escape" || (key.ctrl && key.name === "c")) {
        screen.destroy();
        process.stdout.write("\n\nStopping...\n");
        child.kill("SIGTERM");
      }
    };

    screen.key(["q", "escape", "C-c"], onKey);

    child.on("error", (err) => {
      clearInterval(refreshInterval);
      screen.destroy();
      process.stderr.write("\nFailed to start: " + err.message + "\n");
      resolve();
    });

    child.on("close", (code, signal) => {
      clearInterval(refreshInterval);
      screen.destroy();
      if (signal) {
        process.stdout.write("\nStopped (signal " + signal + ")\n");
      } else if (code !== 0) {
        process.stdout.write("\nProcess exited with code " + code + "\n");
      }
      resolve();
    });

    addLog("Starting Psiphon (protocol: " + protocol + ")...");
    addLog("---");
  });
}

function runTunnelPlain(configDir, corePath, protocol, resolve) {
  const child = spawn(corePath, ["-config", "psiphon.config"], {
    cwd: configDir,
    stdio: ["ignore", "pipe", "pipe"],
  });

  child.stdout.on("data", (data) => process.stdout.write(data.toString()));
  child.stderr.on("data", (data) => process.stderr.write(data.toString()));

  const cleanupStdin = () => {
    if (process.stdin.isTTY) {
      process.stdin.removeListener("data", onKey);
      process.stdin.setRawMode(false);
      process.stdin.pause();
    }
  };

  const onKey = (key) => {
    if (key === "q" || key === "Q" || key === "\u0003") {
      cleanupStdin();
      console.log("\n\nStopping...");
      child.kill("SIGTERM");
    }
  };

  child.on("error", (err) => {
    console.error("\nFailed to start:", err.message);
    cleanupStdin();
    resolve();
  });

  child.on("close", (code, signal) => {
    cleanupStdin();
    if (signal) {
      console.log("\nStopped (signal " + signal + ")");
    } else if (code !== 0) {
      console.log("\nProcess exited with code " + code);
    }
    resolve();
  });

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", onKey);
  }

  console.log("\n  --- Psiphon running (protocol: " + protocol + ") ---");
  console.log("  HTTP proxy:  127.0.0.1:8081");
  console.log("  SOCKS proxy: 127.0.0.1:1081");
  console.log("  Press q to stop\n");
}

async function runApp(options) {
  const configDir = options.configDir || DEFAULT_CONFIG_DIR;
  const corePath = options.core || DEFAULT_CORE_PATH;

  if (!fs.existsSync(corePath)) {
    console.error(`Error: psiphon-tunnel-core not found at ${corePath}`);
    process.exit(1);
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  let runAgain = true;
  while (runAgain) {
    const protocol = await promptProtocol(rl);
    ensureConfigDir(configDir);
    buildConfig(configDir, { protocol, region: options.region || "" });

    console.log(`\n  Starting Psiphon (protocol: ${protocol})...\n`);
    await runTunnel(configDir, corePath, protocol, {
      noTui: options.noTui,
    });

    runAgain = await promptRunAgain(rl);
  }

  rl.close();
  console.log("\n  Goodbye.\n");
  process.exit(0);
}

program
  .name("psiphon-cli")
  .description("Interactive Psiphon tunnel (Conduit, Direct, or Auto)")
  .version("1.0.0");

program
  .command("run", { isDefault: true })
  .description("Run Psiphon (interactive: choose protocol, press q to stop)")
  .option("-c, --config-dir <dir>", "config directory", DEFAULT_CONFIG_DIR)
  .option(
    "--core <path>",
    "path to psiphon-tunnel-core binary",
    DEFAULT_CORE_PATH,
  )
  .option("-r, --region <code>", "egress region (ISO country code)", "")
  .option("--no-tui", "disable split-panel TUI (plain output)")
  .action((options) => {
    runApp(options);
  });

program
  .command("stop")
  .description("Stop the Psiphon tunnel")
  .action(() => {
    const { execSync } = require("child_process");
    try {
      execSync(`pkill -f ${PSIPHON_BIN}`, { stdio: "ignore" });
      console.log("Psiphon tunnel stopped.");
    } catch (e) {
      if (e.status === 1) {
        console.log("No Psiphon tunnel process found.");
      } else {
        console.error("Error:", e.message);
        process.exit(1);
      }
    }
  });

program.parse();
