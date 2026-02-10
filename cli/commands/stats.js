"use strict";

const stats = require("../stats");

function runStatsCommand(options) {
  stats.runStatsCommand(options);
}

module.exports = { runStatsCommand };
