#!/usr/bin/env node
"use strict";

const https = require("https");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execFileSync } = require("child_process");

const ROOT = path.join(__dirname, "..");
const DEST = process.env.SING_BOX_DEST?.trim() || path.join(ROOT, "sing-box");
const VERSION = process.env.SING_BOX_VERSION?.trim()?.replace(/^v/, "") || "";
const USER_AGENT = "psiphon-linux-cli-conduit";

function platformAssetSuffix() {
  const { arch, platform } = process;
  if (platform !== "linux") {
    throw new Error("sing-box download is only supported on Linux");
  }
  if (arch === "x64") {
    return "linux-amd64";
  }
  if (arch === "arm64") {
    return "linux-arm64";
  }
  throw new Error(`Unsupported Linux architecture: ${arch}`);
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    const request = https.get(
      url,
      {
        headers: {
          "User-Agent": USER_AGENT,
          Accept: "application/vnd.github+json",
        },
      },
      (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          res.resume();
          fetchJson(res.headers.location).then(resolve).catch(reject);
          return;
        }
        if (res.statusCode !== 200) {
          reject(
            new Error(`GitHub API returned HTTP ${res.statusCode} for ${url}`),
          );
          return;
        }
        let data = "";
        res.on("data", (chunk) => {
          data += chunk;
        });
        res.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch (err) {
            reject(err);
          }
        });
      },
    );
    request.on("error", reject);
    request.setTimeout(60000, () => {
      request.destroy(new Error(`Timed out fetching ${url}`));
    });
  });
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    const request = https.get(
      url,
      { headers: { "User-Agent": USER_AGENT } },
      (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          file.close();
          fs.unlink(dest, () => {});
          downloadFile(res.headers.location, dest).then(resolve).catch(reject);
          return;
        }
        if (res.statusCode !== 200) {
          reject(new Error(`Download failed with HTTP ${res.statusCode}`));
          return;
        }
        res.pipe(file);
        file.on("finish", () => file.close(resolve));
      },
    );
    request.on("error", reject);
    request.setTimeout(300000, () => {
      request.destroy(new Error(`Timed out downloading ${url}`));
    });
  });
}

function pickAsset(release, suffix) {
  const assets = release.assets.filter(
    (asset) =>
      asset.name.endsWith(`${suffix}.tar.gz`) &&
      !asset.name.includes("legacy") &&
      !asset.name.includes("android"),
  );
  if (assets.length === 0) {
    throw new Error(
      `No ${suffix} tarball found in release ${release.tag_name}`,
    );
  }
  return assets[0];
}

function findFile(root, name) {
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const full = path.join(root, entry.name);
    if (entry.isDirectory()) {
      const found = findFile(full, name);
      if (found) {
        return found;
      }
    } else if (entry.isFile() && entry.name === name) {
      return full;
    }
  }
  return null;
}

function installBinary(source, dest) {
  fs.copyFileSync(source, dest);
  fs.chmodSync(dest, 0o755);
}

async function main() {
  const suffix = platformAssetSuffix();
  const release = VERSION
    ? await fetchJson(
        `https://api.github.com/repos/SagerNet/sing-box/releases/tags/v${VERSION}`,
      )
    : await fetchJson(
        "https://api.github.com/repos/SagerNet/sing-box/releases/latest",
      );

  const asset = pickAsset(release, suffix);
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "sing-box-"));
  const tarball = path.join(tmpDir, asset.name);

  console.log(`Link: ${asset.browser_download_url}`);
  console.log(`Downloading ${asset.name} (${release.tag_name})...`);
  await downloadFile(asset.browser_download_url, tarball);

  execFileSync("tar", ["-xzf", tarball, "-C", tmpDir]);

  const extracted = findFile(tmpDir, "sing-box");
  if (!extracted) {
    throw new Error("Archive did not contain a sing-box binary");
  }

  const bundleDir = path.dirname(DEST);
  fs.mkdirSync(bundleDir, { recursive: true });
  installBinary(extracted, DEST);

  const libcronet = path.join(path.dirname(extracted), "libcronet.so");
  if (!fs.existsSync(libcronet)) {
    throw new Error("Archive did not contain libcronet.so next to sing-box");
  }
  const destLib = path.join(bundleDir, "libcronet.so");
  fs.copyFileSync(libcronet, destLib);
  fs.chmodSync(destLib, 0o755);

  fs.rmSync(tmpDir, { recursive: true, force: true });

  const stat = fs.statSync(DEST);
  console.log(
    `Installed sing-box ${release.tag_name} -> ${path.relative(ROOT, DEST)} (${stat.size} bytes)`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
