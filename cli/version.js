"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const GENERATED_VERSION_PATH = path.join(__dirname, "version.generated.json");

function getVersionFromGit() {
  const hash = execFileSync("git", ["rev-parse", "--short=6", "HEAD"], {
    encoding: "utf-8",
    stdio: ["ignore", "pipe", "ignore"],
  }).trim();
  const date = execFileSync("git", ["log", "-1", "--format=%ci", "HEAD"], {
    encoding: "utf-8",
    stdio: ["ignore", "pipe", "ignore"],
  })
    .trim()
    .slice(0, 10);
  return `${hash} ${date}`;
}

function getVersion() {
  if (fs.existsSync(GENERATED_VERSION_PATH)) {
    try {
      const data = JSON.parse(fs.readFileSync(GENERATED_VERSION_PATH, "utf-8"));
      if (data.version) return data.version;
    } catch (_) {
      // fall through to git lookup
    }
  }

  try {
    return getVersionFromGit();
  } catch (_) {
    return "unknown";
  }
}

module.exports = { getVersion };
