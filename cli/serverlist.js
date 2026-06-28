"use strict";

const fs = require("fs");
const path = require("path");
const https = require("https");
const { execFileSync } = require("child_process");
const config = require("./config");
const { FILES } = require("./constants");

function readConfig(configDir) {
  const cfgPath = path.join(configDir, FILES.CONFIG);
  if (!fs.existsSync(cfgPath)) {
    throw new Error(
      `Config file not found at ${cfgPath}. Run 'psiphon-cli connect' once to initialize it.`,
    );
  }
  return JSON.parse(fs.readFileSync(cfgPath, "utf-8"));
}

function downloadHttps(url, destPath) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    https
      .get(url, (res) => {
        if (res.statusCode !== 200) {
          file.close();
          fs.unlink(destPath, () => {
            // ignore unlink error
          });
          reject(new Error(`HTTP ${res.statusCode} when downloading server list`));
          return;
        }
        res.pipe(file);
        file.on("finish", () => {
          file.close(() => resolve());
        });
      })
      .on("error", (err) => {
        file.close();
        fs.unlink(destPath, () => {
          // ignore unlink error
        });
        reject(err);
      });
  });
}

function downloadWithCurl(url, destPath) {
  fs.mkdirSync(path.dirname(destPath), { recursive: true });
  execFileSync(
    "curl",
    ["-fsSL", "--max-time", "60", "-o", destPath, url],
    { stdio: ["ignore", "pipe", "pipe"] },
  );
}

function shouldTryCurl(err) {
  const code = err && err.code;
  return (
    code === "ENOTFOUND" ||
    code === "EAI_AGAIN" ||
    code === "ETIMEDOUT" ||
    code === "ECONNREFUSED" ||
    code === "ECONNRESET"
  );
}

async function download(url, destPath) {
  try {
    await downloadHttps(url, destPath);
  } catch (err) {
    if (!shouldTryCurl(err)) {
      throw err;
    }
    try {
      downloadWithCurl(url, destPath);
    } catch (curlErr) {
      const nodeMsg = err.message || String(err);
      const curlMsg = curlErr.message || String(curlErr);
      throw new Error(
        `Could not download server list (${nodeMsg}; curl fallback: ${curlMsg})`,
      );
    }
  }
}

function readConfigFile(configPath) {
  if (!fs.existsSync(configPath)) {
    throw new Error(`Config file not found at ${configPath}`);
  }
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

async function downloadFromConfigFile(configPath, destPath) {
  const cfg = readConfigFile(configPath);
  const url = cfg.RemoteServerListUrl;

  if (!url) {
    throw new Error(
      "RemoteServerListUrl is not set in psiphon.config; cannot download server list.",
    );
  }

  fs.mkdirSync(path.dirname(destPath), { recursive: true });
  await download(url, destPath);
  return { url, destPath };
}

async function refreshServerList(configDir) {
  const effectiveConfigDir = configDir || config.DEFAULT_CONFIG_DIR;
  config.ensureConfigDir(effectiveConfigDir);
  const cfg = readConfig(effectiveConfigDir);
  const url = cfg.RemoteServerListUrl;
  const filename = cfg.RemoteServerListDownloadFilename || "remote_server_list";

  if (!url) {
    throw new Error(
      "RemoteServerListUrl is not set in psiphon.config; cannot refresh server list.",
    );
  }

  const destPath = path.join(effectiveConfigDir, filename);
  await download(url, destPath);
  return { url, destPath };
}

module.exports = {
  refreshServerList,
  downloadFromConfigFile,
};

