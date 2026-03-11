"use strict";

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const { PSIPHON_BIN, STATS_UPDATE_MS, FILES, IS_WIN } = require("./constants");
const config = require("./config");
const stats = require("./stats");

function getCorePath() {
  const nextToBinary = path.join(path.dirname(process.execPath), PSIPHON_BIN);
  if (process.pkg) {
    if (fs.existsSync(nextToBinary)) {
      return nextToBinary;
    }
    const bundledPath = path.join(__dirname, "..", PSIPHON_BIN);
    if (fs.existsSync(bundledPath)) {
      const extractedPath = path.join(
        config.DEFAULT_CONFIG_DIR,
        PSIPHON_BIN,
      );
      config.ensureConfigDir(config.DEFAULT_CONFIG_DIR);
      if (!fs.existsSync(extractedPath)) {
        fs.copyFileSync(bundledPath, extractedPath);
        if (!IS_WIN) fs.chmodSync(extractedPath, 0o755);
      }
      return extractedPath;
    }
  }
  return path.join(config.getProjectRoot(), PSIPHON_BIN);
}

function runConnect(configDir, corePath, protocol, options = {}) {
  return new Promise((resolve) => {
    const tunnelStartTime = Date.now();
    const statsState = {
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
      startedAt: tunnelStartTime,
    };
    let lastBytesTime = 0;
    let logStream = null;
    let stdoutBuf = "";
    let stderrBuf = "";
    const pidPath = path.join(configDir, FILES.PID);
    const statsPath = path.join(configDir, FILES.STATS);
    const logPath = path.join(configDir, FILES.LOG);

    try {
      logStream = fs.createWriteStream(logPath, { flags: "w" });
    } catch (_) {
      logStream = null;
    }

    function processLine(line) {
      if (!line.trim()) return;
      if (logStream) {
        try {
          logStream.write(line + "\n");
        } catch (_) {
          // ignore log write errors
        }
      }
      try {
        const notice = JSON.parse(line);
        const { noticeType, data = {} } = notice;
        if (
          noticeType === "RemoteServerListDownloadFailed" ||
          noticeType === "RemoteServerListFetchFailed"
        ) {
          // eslint-disable-next-line no-console
          console.warn(
            "Remote server list download failed; psiphon-tunnel-core will rely on any cached local list if available.",
          );
        }
        if (noticeType === "ListeningSocksProxyPort")
          statsState.socksProxy = `127.0.0.1:${data.port}`;
        if (noticeType === "ListeningHttpProxyPort")
          statsState.httpProxy = `127.0.0.1:${data.port}`;
        if (noticeType === "Tunnels") {
          statsState.tunnelCount = data.count || 0;
          statsState.status =
            statsState.tunnelCount > 0
              ? "connected"
              : statsState.status === "connected"
                ? "disconnecting"
                : "connecting";
        }
        if (noticeType === "ClientRegion")
          statsState.clientRegion = data.region || "-";
        if (noticeType === "ConnectedServerRegion")
          statsState.egressRegion = data.serverRegion || "-";
        if (noticeType === "TrafficRateLimits") {
          statsState.downstreamBps =
            data.downstreamBytesPerSecond || 0;
          statsState.upstreamBps = data.upstreamBytesPerSecond || 0;
        }
        if (noticeType === "BytesTransferred") {
          const received = data.received || 0;
          const sent = data.sent || 0;
          statsState.totalDownBytes += received;
          statsState.totalUpBytes += sent;
          const now = Date.now();
          if (lastBytesTime > 0 && (received > 0 || sent > 0)) {
            const elapsedSec = (now - lastBytesTime) / 1000;
            if (elapsedSec > 0) {
              statsState.downstreamBps = Math.round(received / elapsedSec);
              statsState.upstreamBps = Math.round(sent / elapsedSec);
            }
          }
          lastBytesTime = now;
        }
        if (noticeType === "TotalBytesTransferred") {
          statsState.totalDownBytes =
            data.received ?? statsState.totalDownBytes;
          statsState.totalUpBytes = data.sent ?? statsState.totalUpBytes;
        }
        if (noticeType === "ActiveTunnel")
          statsState.tunnelProtocol = data.protocol || "-";
        if (noticeType === "AvailableEgressRegions")
          statsState.availableRegions = (data.regions || []).length;
        if (noticeType === "ServerTimestamp")
          statsState.diagnosticID = data.diagnosticID || "-";
        if (noticeType === "Exiting") statsState.status = "exiting";
      } catch (_) {}
    }

    function processStream(str, buf) {
      buf += str;
      const lines = buf.split("\n");
      const remaining = lines.pop() || "";
      for (const line of lines) processLine(line);
      return remaining;
    }

    const child = spawn(corePath, ["-config", FILES.CONFIG], {
      cwd: configDir,
      stdio: ["ignore", "pipe", "pipe"],
    });

    fs.writeFileSync(pidPath, String(child.pid), "utf-8");

    child.stdout.on("data", (data) => {
      stdoutBuf = processStream(data.toString(), stdoutBuf);
    });
    child.stderr.on("data", (data) => {
      stderrBuf = processStream(data.toString(), stderrBuf);
    });

    const statsInterval = setInterval(() => {
      statsState.uptimeMs = Date.now() - tunnelStartTime;
      stats.writeStatsFile(configDir, statsState);
    }, STATS_UPDATE_MS);

    function cleanup() {
      clearInterval(statsInterval);
      try {
        if (logStream) {
          logStream.end();
          logStream = null;
        }
        if (fs.existsSync(pidPath)) fs.unlinkSync(pidPath);
        if (fs.existsSync(statsPath)) fs.unlinkSync(statsPath);
      } catch (_) {}
    }

    child.on("error", (err) => {
      cleanup();
      console.error("\nFailed to start:", err.message);
      resolve();
    });

    child.on("close", (code, signal) => {
      cleanup();
      if (signal) {
        console.log("\nStopped (signal " + signal + ")");
      } else if (code !== 0) {
        console.log("\nProcess exited with code " + code);
      }
      resolve();
    });

    console.log("\n  Connecting... (protocol: " + protocol + ")");
    console.log("  HTTP proxy:  127.0.0.1:8081  SOCKS proxy: 127.0.0.1:1081");
    console.log(
      "  Run 'psiphon-cli stats' in another terminal. Ctrl+C to disconnect.\n",
    );
  });
}

module.exports = {
  getCorePath,
  runConnect,
};
