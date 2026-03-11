"use strict";

const fs = require("fs");
const path = require("path");
const https = require("https");
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

function download(url, destPath) {
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
};

