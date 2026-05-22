"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const rootDir = path.join(__dirname, "..");
const outputPath = path.join(rootDir, "cli", "version.generated.json");

const hash = execFileSync("git", ["rev-parse", "--short=6", "HEAD"], {
  cwd: rootDir,
  encoding: "utf-8",
}).trim();
const date = execFileSync("git", ["log", "-1", "--format=%ci", "HEAD"], {
  cwd: rootDir,
  encoding: "utf-8",
})
  .trim()
  .slice(0, 10);

fs.writeFileSync(
  outputPath,
  JSON.stringify({ version: `${hash} ${date}` }, null, 2) + "\n",
  "utf-8",
);

console.log(`Generated version: ${hash} ${date}`);
