"use strict";

const fs = require("fs");
const path = require("path");
const { getDefaultConfigDir } = require("../cli/constants");

const rootDir = path.join(__dirname, "..");
const destPath = path.join(rootDir, "configs", "server_list_compressed");

function resolveConfigDir() {
  const fromEnv = process.env.PSIPHON_CONFIG_DIR;
  if (fromEnv && fromEnv.trim()) {
    return fromEnv.trim();
  }
  return getDefaultConfigDir();
}

function resolveDownloadFilename(configDir) {
  const configPath = path.join(configDir, "psiphon.config");
  if (!fs.existsSync(configPath)) {
    return "remote_server_list";
  }

  try {
    const cfg = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    return cfg.RemoteServerListDownloadFilename || "remote_server_list";
  } catch {
    return "remote_server_list";
  }
}

function findSource() {
  const repoOnly = process.argv.includes("--repo-only");

  if (repoOnly && fs.existsSync(destPath)) {
    return destPath;
  }

  const explicit = process.env.PSIPHON_SERVER_LIST?.trim();
  if (explicit) {
    if (fs.existsSync(explicit)) {
      return explicit;
    }
    console.warn(`PSIPHON_SERVER_LIST is set but file not found: ${explicit}`);
  }

  const configDir = resolveConfigDir();
  const filename = resolveDownloadFilename(configDir);
  const candidates = [
    path.join(configDir, filename),
    path.join(configDir, "server_list_compressed"),
    path.join(configDir, "remote_server_list"),
  ];

  const seen = new Set();
  for (const candidate of candidates) {
    if (seen.has(candidate)) {
      continue;
    }
    seen.add(candidate);
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  if (fs.existsSync(destPath)) {
    return destPath;
  }

  return null;
}

function main() {
  const stampPath = process.argv[2];
  const source = findSource();

  if (!source) {
    console.error(
      "No server list found on this machine. Expected one of:\n" +
        `  ${path.join(resolveConfigDir(), "remote_server_list")}\n` +
        "Set PSIPHON_SERVER_LIST to a local file path, or run psiphon-cli once to cache a list.",
    );
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(destPath), { recursive: true });
  fs.copyFileSync(source, destPath);

  const stat = fs.statSync(destPath);
  console.log(
    `Bundled server list: ${path.relative(rootDir, destPath)} (${stat.size} bytes, from ${source})`,
  );

  if (stampPath) {
    fs.writeFileSync(stampPath, `${source}\n${stat.size}\n`);
  }
}

main();
