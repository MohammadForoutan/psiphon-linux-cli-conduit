"use strict";

const fs = require("fs");
const path = require("path");
const {
  DEFAULT_CONFIG_DIR,
  DIRECT_PROTOCOLS,
  CONDUIT_PROTOCOLS,
  FILES,
} = require("./constants");

function getProjectRoot() {
  if (process.pkg) {
    return path.dirname(process.execPath);
  }
  return path.join(__dirname, "..");
}

function getDefaultConfigPath() {
  return path.join(__dirname, "..", "configs", FILES.CONFIG);
}

function ensureConfigDir(configDir) {
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }
}

function getOrCreateConfig(configDir) {
  const userConfigPath = path.join(configDir, FILES.CONFIG);
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

  const configPath = path.join(configDir, FILES.CONFIG);
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf-8");
  return configPath;
}

module.exports = {
  getProjectRoot,
  getDefaultConfigPath,
  ensureConfigDir,
  getOrCreateConfig,
  buildConfig,
  DEFAULT_CONFIG_DIR,
};
