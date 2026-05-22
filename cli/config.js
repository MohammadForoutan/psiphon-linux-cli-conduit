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
  // Seed bundled server list snapshot into user config dir on first run
  try {
    const defaultListPath = path.join(
      getProjectRoot(),
      "configs",
      "server_list_compressed",
    );
    const userListPath = path.join(configDir, "remote_server_list");
    if (fs.existsSync(defaultListPath) && !fs.existsSync(userListPath)) {
      fs.copyFileSync(defaultListPath, userListPath);
    }
  } catch (_) {
    // ignore seeding errors; core can still attempt remote download
  }
  return config;
}

const SUPPORTED_PROXY_SCHEMES = ["http:", "https:", "socks5:"];

function validateUpstreamProxyUrl(url) {
  if (!url || typeof url !== "string" || !url.trim()) return null;
  let parsed;
  try {
    parsed = new URL(url.trim());
  } catch {
    return "Upstream proxy URL is not a valid URL";
  }
  if (!SUPPORTED_PROXY_SCHEMES.includes(parsed.protocol)) {
    return `Upstream proxy URL must use one of: ${SUPPORTED_PROXY_SCHEMES.join(", ")}`;
  }
  return null;
}

function buildConfig(configDir, options) {
  const config = getOrCreateConfig(configDir);
  config.EgressRegion = options.region || "";
  config.EmitBytesTransferred = true;

  if (options.enableTimeout) {
    delete config.EstablishTunnelTimeoutSeconds;
  } else {
    config.EstablishTunnelTimeoutSeconds = 0;
  }

  if (options.enableLan) {
    config.ListenInterface = "any";
  } else {
    delete config.ListenInterface;
  }

  if (options.protocol === "conduit") {
    config.LimitTunnelProtocols = CONDUIT_PROTOCOLS;
  } else if (options.protocol === "direct") {
    config.LimitTunnelProtocols = DIRECT_PROTOCOLS.slice();
  } else {
    delete config.LimitTunnelProtocols;
  }

  const upstreamProxyUrl =
    options.upstreamProxyUrl && String(options.upstreamProxyUrl).trim();
  if (upstreamProxyUrl) {
    const err = validateUpstreamProxyUrl(upstreamProxyUrl);
    if (err) {
      throw new Error(`Invalid upstream proxy: ${err}`);
    }
    config.UpstreamProxyURL = upstreamProxyUrl;
  } else {
    delete config.UpstreamProxyURL;
  }

   if (
    !config.RemoteServerListUrl ||
    !config.RemoteServerListSignaturePublicKey
  ) {
    // eslint-disable-next-line no-console
    console.warn(
      "Warning: RemoteServerListUrl/RemoteServerListSignaturePublicKey are not set in psiphon.config; official server list will not be used.",
    );
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
  validateUpstreamProxyUrl,
  DEFAULT_CONFIG_DIR,
};
