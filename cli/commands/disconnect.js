"use strict";

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const config = require("../config");
const { PSIPHON_BIN, FILES, IS_WIN } = require("../constants");

function killByPid(pid) {
  if (IS_WIN) {
    execSync(`taskkill /F /PID ${pid}`, { stdio: "ignore" });
  } else {
    process.kill(pid, "SIGTERM");
  }
}

function killByName() {
  if (IS_WIN) {
    execSync(`taskkill /F /IM "${PSIPHON_BIN}"`, { stdio: "ignore" });
  } else {
    execSync(`pkill -f ${PSIPHON_BIN}`, { stdio: "ignore" });
  }
}

function runDisconnectCommand(options) {
  const configDir = options.configDir || config.DEFAULT_CONFIG_DIR;
  const pidPath = path.join(configDir, FILES.PID);
  const statsPath = path.join(configDir, FILES.STATS);

  try {
    if (fs.existsSync(pidPath)) {
      const pid = parseInt(fs.readFileSync(pidPath, "utf-8"), 10);
      killByPid(pid);
      fs.unlinkSync(pidPath);
      if (fs.existsSync(statsPath)) fs.unlinkSync(statsPath);
      console.log("Disconnected.");
    } else {
      killByName();
      console.log("Disconnected.");
    }
  } catch (e) {
    if (e.code === "ESRCH") {
      if (fs.existsSync(pidPath)) fs.unlinkSync(pidPath);
      if (fs.existsSync(statsPath)) fs.unlinkSync(statsPath);
      console.log("Not connected.");
    } else if (e.status === 1 || (IS_WIN && e.status === 128)) {
      // pkill exits 1 when no process; taskkill can exit 128 when not found
      console.log("Not connected.");
    } else {
      console.error("Error:", e.message);
      process.exit(1);
    }
  }
}

module.exports = { runDisconnectCommand };
