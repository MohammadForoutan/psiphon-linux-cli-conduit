"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const rootDir = path.join(__dirname, "..");
const outputPath = path.join(rootDir, "cli", "version.generated.json");
const packagePath = path.join(rootDir, "package.json");

function readGitValue(args) {
  return execFileSync("git", args, {
    cwd: rootDir,
    encoding: "utf-8",
  }).trim();
}

const pkg = JSON.parse(fs.readFileSync(packagePath, "utf-8"));
const packageVersion = pkg.version || "0.0.0";

let hash = "unknown";
let date = "unknown";

try {
  hash = readGitValue(["rev-parse", "--short=6", "HEAD"]);
  date = readGitValue(["log", "-1", "--format=%ci", "HEAD"]).slice(0, 10);
} catch (_) {
  // git may be unavailable in some build environments
}

const version = `${packageVersion} ${hash} ${date}`;
const payload = { version, packageVersion, commit: hash, date };

fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2) + "\n", "utf-8");

const guiOutputIndex = process.argv.indexOf("--gui-output");
if (guiOutputIndex !== -1 && process.argv[guiOutputIndex + 1]) {
  const guiOutputPath = process.argv[guiOutputIndex + 1];
  fs.mkdirSync(path.dirname(guiOutputPath), { recursive: true });
  fs.writeFileSync(guiOutputPath, JSON.stringify(payload, null, 2) + "\n", "utf-8");
}

console.log(`Generated version: ${version}`);
