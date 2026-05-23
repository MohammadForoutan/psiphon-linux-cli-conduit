"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const GENERATED_VERSION_PATH = path.join(__dirname, "version.generated.json");
const PACKAGE_PATH = path.join(__dirname, "..", "package.json");

function getPackageVersion() {
  try {
    const pkg = JSON.parse(fs.readFileSync(PACKAGE_PATH, "utf-8"));
    return pkg.version || "";
  } catch (_) {
    return "";
  }
}

function formatVersion(packageVersion, hash, date) {
  const parts = [packageVersion, hash, date].filter(Boolean);
  return parts.join(" ");
}

function getVersionFromGit() {
  const packageVersion = getPackageVersion();
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
  return formatVersion(packageVersion, hash, date);
}

function getVersion() {
  if (fs.existsSync(GENERATED_VERSION_PATH)) {
    try {
      const data = JSON.parse(fs.readFileSync(GENERATED_VERSION_PATH, "utf-8"));
      if (data.version) return data.version;
      if (data.commit && data.date) {
        return formatVersion(data.packageVersion || getPackageVersion(), data.commit, data.date);
      }
    } catch (_) {
      // fall through to git lookup
    }
  }

  try {
    return getVersionFromGit();
  } catch (_) {
    const packageVersion = getPackageVersion();
    return packageVersion || "unknown";
  }
}

module.exports = { getVersion };
