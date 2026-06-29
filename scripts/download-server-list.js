#!/usr/bin/env node
"use strict";

const path = require("path");
const fs = require("fs");
const { downloadFromConfigFile } = require("../cli/serverlist");

const rootDir = path.join(__dirname, "..");
const configPath =
  process.env.PSIPHON_CONFIG_FILE?.trim() ||
  path.join(rootDir, "configs", "psiphon.config");
const destPath =
  process.env.PSIPHON_SERVER_LIST_DEST?.trim() ||
  path.join(rootDir, "configs", "server_list_compressed");

async function main() {
  const { url, destPath: savedPath } = await downloadFromConfigFile(
    configPath,
    destPath,
  );
  const stat = fs.statSync(savedPath);
  console.log(
    `Downloaded server list: ${path.relative(rootDir, savedPath)} (${stat.size} bytes, from ${url})`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
