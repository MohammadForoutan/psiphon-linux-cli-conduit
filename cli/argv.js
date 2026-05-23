"use strict";

const { parseArgs } = require("util");
const config = require("./config");
const core = require("./core");
const { getVersion } = require("./version");

const PROGRAM_NAME = "psiphon-cli";

const COMMANDS = {
  connect: {
    description: "Connect (choose protocol & region, then run tunnel)",
    options: {
      region: {
        type: "string",
        short: "r",
        default: "",
      },
      "upstream-proxy": {
        type: "string",
        short: "p",
        default: process.env.PSIPHON_UPSTREAM_PROXY || "",
      },
      "enable-timeout": {
        type: "boolean",
        default: false,
      },
      "enable-lan": {
        type: "boolean",
        default: false,
      },
    },
  },
  disconnect: {
    description: "Disconnect the tunnel",
    options: {},
  },
  stats: {
    description: "Show tunnel stats (updates every 2s)",
    options: {},
  },
  logs: {
    description: "Show live logs from psiphon-tunnel-core (pretty-printed JSON)",
    options: {
      lines: {
        type: "string",
        short: "n",
        default: "50",
      },
    },
  },
  "refresh-server-list": {
    description:
      "Download or update the official Psiphon server list into the config directory",
    options: {},
  },
};

const GLOBAL_OPTIONS = {
  "config-dir": {
    type: "string",
    short: "c",
    default: config.DEFAULT_CONFIG_DIR,
  },
  core: {
    type: "string",
    default: core.getCorePath(),
  },
  help: {
    type: "boolean",
    short: "h",
    default: false,
  },
  version: {
    type: "boolean",
    short: "V",
    default: false,
  },
};

const KNOWN_COMMANDS = Object.keys(COMMANDS);
const ALL_OPTIONS = {
  ...GLOBAL_OPTIONS,
  ...COMMANDS.connect.options,
  ...COMMANDS.logs.options,
};
const VALUE_OPTIONS = new Set(
  Object.entries(ALL_OPTIONS)
    .filter(([, definition]) => definition.type === "string")
    .flatMap(([name, definition]) =>
      definition.short ? [`--${name}`, `-${definition.short}`] : [`--${name}`],
    ),
);

function toCamelCase(key) {
  return key.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

function getDefaultValues(options) {
  return Object.fromEntries(
    Object.entries(options)
      .filter(([, definition]) => Object.hasOwn(definition, "default"))
      .map(([key, definition]) => [key, definition.default]),
  );
}

function getParseOptions(options) {
  return Object.fromEntries(
    Object.entries(options).map(([key, definition]) => [
      key,
      {
        type: definition.type,
        ...(definition.short ? { short: definition.short } : {}),
      },
    ]),
  );
}

function normalizeOptions(values) {
  return Object.fromEntries(
    Object.entries(values).map(([key, value]) => [toCamelCase(key), value]),
  );
}

function optionConsumesNextValue(arg) {
  return VALUE_OPTIONS.has(arg);
}

function extractCommand(args) {
  const remaining = [];
  let command = "connect";
  let foundCommand = false;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (optionConsumesNextValue(arg)) {
      remaining.push(arg);
      if (index + 1 < args.length) {
        remaining.push(args[index + 1]);
        index += 1;
      }
      continue;
    }

    if (!arg.startsWith("-") && KNOWN_COMMANDS.includes(arg) && !foundCommand) {
      command = arg;
      foundCommand = true;
      continue;
    }

    remaining.push(arg);
  }

  return { command, args: remaining };
}

function parseCliArgs(argv = process.argv) {
  const args = argv.slice(2);
  const { command, args: parseableArgs } = extractCommand(args);
  const options = {
    ...GLOBAL_OPTIONS,
    ...COMMANDS[command].options,
  };

  const parsed = parseArgs({
    args: parseableArgs,
    options: getParseOptions(options),
    strict: true,
    allowPositionals: false,
  });

  return {
    command,
    options: normalizeOptions({
      ...getDefaultValues(options),
      ...parsed.values,
    }),
  };
}

function printVersion() {
  console.log(getVersion());
}

function printHelp() {
  console.log(`Usage: ${PROGRAM_NAME} [options] [command]

Psiphon tunnel CLI: connect, disconnect, stats

Options:
  -c, --config-dir <dir>      config directory
  --core <path>               path to psiphon-tunnel-core binary
  -h, --help                  display help for command
  -V, --version               output the version number

Commands:
  connect [options]           ${COMMANDS.connect.description}
  disconnect                  ${COMMANDS.disconnect.description}
  stats                       ${COMMANDS.stats.description}
  logs [options]              ${COMMANDS.logs.description}
  refresh-server-list         ${COMMANDS["refresh-server-list"].description}

Connect options:
  -r, --region <code>         egress region (ISO country code)
  -p, --upstream-proxy <url>  upstream proxy URL (e.g. http://proxy:8080 or socks5://127.0.0.1:1080)
  --enable-timeout            use psiphon-tunnel-core establish tunnel timeout (disabled by default)
  --enable-lan                listen on all interfaces so HTTP/SOCKS proxies are reachable on the LAN

Logs options:
  -n, --lines <number>        number of recent log lines to show initially`);
}

module.exports = {
  parseCliArgs,
  printHelp,
  printVersion,
};
