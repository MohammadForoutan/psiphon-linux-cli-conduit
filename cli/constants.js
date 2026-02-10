"use strict";

const path = require("path");
const os = require("os");

const PLATFORM = process.platform; // 'linux' | 'win32'
const IS_WIN = PLATFORM === "win32";

function getPsiphonBinName() {
  if (PLATFORM === "win32") {
    return process.arch === "x64"
      ? "psiphon-tunnel-core-windows-amd64.exe"
      : "psiphon-tunnel-core-i686.exe";
  }
  return "psiphon-tunnel-core-x86_64";
}

function getDefaultConfigDir() {
  if (PLATFORM === "win32") {
    return path.join(os.homedir(), "AppData", "Local", "psiphon-cli");
  }
  return path.join(os.homedir(), ".config", "psiphon-cli");
}

const DIRECT_PROTOCOLS = [
  "SSH",
  "OSSH",
  "TLS-OSSH",
  "UNFRONTED-MEEK-OSSH",
  "UNFRONTED-MEEK-HTTPS-OSSH",
  "UNFRONTED-MEEK-SESSION-TICKET-OSSH",
  "FRONTED-MEEK-OSSH",
  "FRONTED-MEEK-HTTP-OSSH",
  "QUIC-OSSH",
  "FRONTED-MEEK-QUIC-OSSH",
  "TAPDANCE-OSSH",
  "CONJURE-OSSH",
  "SHADOWSOCKS-OSSH",
];

const CONDUIT_PROTOCOLS = [
  "INPROXY-WEBRTC-SSH",
  "INPROXY-WEBRTC-OSSH",
  "INPROXY-WEBRTC-TLS-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
  "INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
  "INPROXY-WEBRTC-QUIC-OSSH",
  "INPROXY-WEBRTC-FRONTED-MEEK-QUIC-OSSH",
  "INPROXY-WEBRTC-SHADOWSOCKS-OSSH",
];

const PSIPHON_BIN = getPsiphonBinName();
const DEFAULT_CONFIG_DIR = getDefaultConfigDir();
const STATS_UPDATE_MS = 2000;

const FILES = {
  CONFIG: "psiphon.config",
  STATS: "stats.json",
  PID: "psiphon.pid",
};

module.exports = {
  PLATFORM,
  IS_WIN,
  getPsiphonBinName,
  getDefaultConfigDir,
  DIRECT_PROTOCOLS,
  CONDUIT_PROTOCOLS,
  PSIPHON_BIN,
  DEFAULT_CONFIG_DIR,
  STATS_UPDATE_MS,
  FILES,
};
