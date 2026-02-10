"use strict";

function formatBytesPerSec(bps) {
  if (bps >= 1024 * 1024) return (bps / 1024 / 1024).toFixed(2) + " MB/s";
  if (bps >= 1024) return (bps / 1024).toFixed(2) + " KB/s";
  return bps + " B/s";
}

function formatBytes(bytes) {
  if (bytes >= 1024 * 1024 * 1024)
    return (bytes / 1024 / 1024 / 1024).toFixed(2) + " GB";
  if (bytes >= 1024 * 1024) return (bytes / 1024 / 1024).toFixed(2) + " MB";
  if (bytes >= 1024) return (bytes / 1024).toFixed(2) + " KB";
  return bytes + " B";
}

function formatUptime(ms) {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const h = Math.floor(m / 60);
  if (h > 0) return `${h}h ${m % 60}m`;
  if (m > 0) return `${m}m ${s % 60}s`;
  return `${s}s`;
}

module.exports = {
  formatBytesPerSec,
  formatBytes,
  formatUptime,
};
