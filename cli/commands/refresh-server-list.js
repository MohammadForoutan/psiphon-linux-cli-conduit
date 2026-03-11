"use strict";

const { refreshServerList } = require("../serverlist");

async function runRefreshServerListCommand(options) {
  try {
    const { url, destPath } = await refreshServerList(options.configDir);
    // eslint-disable-next-line no-console
    console.log(
      `Server list refreshed from ${url} and saved to ${destPath}. psiphon-tunnel-core will use it on next connect.`,
    );
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error(`Failed to refresh server list: ${err.message}`);
    process.exitCode = 1;
  }
}

module.exports = {
  runRefreshServerListCommand,
};

