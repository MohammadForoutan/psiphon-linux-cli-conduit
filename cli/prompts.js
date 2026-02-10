"use strict";

const { REGIONS, flagForRegionCode } = require("./regions");

function promptProtocol(rl) {
  return new Promise((resolve) => {
    console.log("\n  Connection protocol:");
    console.log("    1) auto    - Let Psiphon choose (default)");
    console.log("    2) conduit - Via volunteer stations");
    console.log("    3) direct  - To Psiphon servers");
    rl.question("\n  Select (1/2/3): ", (answer) => {
      const trimmed = (answer || "1").trim().toLowerCase();
      if (trimmed === "2" || trimmed === "conduit") {
        resolve("conduit");
      } else if (trimmed === "3" || trimmed === "direct") {
        resolve("direct");
      } else {
        resolve("auto");
      }
    });
  });
}

function promptRegion(rl) {
  return new Promise((resolve) => {
    console.log("\n  Egress region:");
    console.log("    1) auto - Let Psiphon choose (default)");
    console.log("    2) Select a region:");
    REGIONS.forEach((r, i) => {
      const n = i + 3;
      const flag = flagForRegionCode(r.code);
      console.log(`       ${n}) ${flag} ${r.code} - ${r.name}`);
    });
    const maxN = REGIONS.length + 2;
    rl.question(`\n  Select (1-${maxN}): `, (answer) => {
      const trimmed = (answer || "1").trim();
      const num = parseInt(trimmed, 10);
      if (num >= 3 && num <= maxN) {
        resolve(REGIONS[num - 3].code);
      } else {
        resolve("");
      }
    });
  });
}

module.exports = {
  promptProtocol,
  promptRegion,
};
