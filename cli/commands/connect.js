"use strict";

const readline = require("readline");
const fs = require("fs");
const config = require("../config");
const core = require("../core");
const prompts = require("../prompts");

async function runConnectCommand(options) {
  const configDir = options.configDir || config.DEFAULT_CONFIG_DIR;
  const corePath = options.core || core.getCorePath();

  if (!fs.existsSync(corePath)) {
    console.error(`Error: psiphon-tunnel-core not found at ${corePath}`);
    process.exit(1);
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const protocol = await prompts.promptProtocol(rl);
  const region =
    options.region !== undefined && options.region !== ""
      ? options.region
      : await prompts.promptRegion(rl);
  rl.close();

  const upstreamProxyUrl =
    (options.upstreamProxy && options.upstreamProxy.trim()) ||
    (process.env.PSIPHON_UPSTREAM_PROXY &&
      process.env.PSIPHON_UPSTREAM_PROXY.trim()) ||
    "";

  config.ensureConfigDir(configDir);
  try {
    config.buildConfig(configDir, {
      protocol,
      region: region || "",
      upstreamProxyUrl,
    });
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
  await core.runConnect(configDir, corePath, protocol, options);
  process.exit(0);
}

module.exports = { runConnectCommand };
