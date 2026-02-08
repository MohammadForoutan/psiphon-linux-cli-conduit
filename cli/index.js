#!/usr/bin/env node

const { program } = require('commander');
const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');
const { spawn } = require('child_process');

const DIRECT_PROTOCOLS = [
    'SSH', 'OSSH', 'TLS-OSSH', 'UNFRONTED-MEEK-OSSH', 'UNFRONTED-MEEK-HTTPS-OSSH',
    'UNFRONTED-MEEK-SESSION-TICKET-OSSH', 'FRONTED-MEEK-OSSH', 'FRONTED-MEEK-HTTP-OSSH',
    'QUIC-OSSH', 'FRONTED-MEEK-QUIC-OSSH', 'TAPDANCE-OSSH', 'CONJURE-OSSH', 'SHADOWSOCKS-OSSH'
];
const CONDUIT_PROTOCOLS = [
    'INPROXY-WEBRTC-SSH', 'INPROXY-WEBRTC-OSSH', 'INPROXY-WEBRTC-TLS-OSSH',
    'INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH', 'INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH',
    'INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH', 'INPROXY-WEBRTC-FRONTED-MEEK-OSSH',
    'INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH', 'INPROXY-WEBRTC-QUIC-OSSH',
    'INPROXY-WEBRTC-FRONTED-MEEK-QUIC-OSSH', 'INPROXY-WEBRTC-SHADOWSOCKS-OSSH'
];

const PSIPHON_BIN = 'psiphon-tunnel-core-x86_64';
const DEFAULT_CONFIG_DIR = path.join(os.homedir(), '.config', 'psiphon-cli');
const DEFAULT_CORE_PATH = path.join(__dirname, '..', 'psiphon-tunnel-core-x86_64');

function getDefaultConfigPath() {
    return path.join(__dirname, '..', 'configs', 'psiphon.config');
}

function ensureConfigDir(configDir) {
    if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
    }
}

function getOrCreateConfig(configDir) {
    const userConfigPath = path.join(configDir, 'psiphon.config');
    if (fs.existsSync(userConfigPath)) {
        return JSON.parse(fs.readFileSync(userConfigPath, 'utf-8'));
    }
    const defaultConfigPath = getDefaultConfigPath();
    if (!fs.existsSync(defaultConfigPath)) {
        throw new Error(`Default config not found at ${defaultConfigPath}`);
    }
    const config = JSON.parse(fs.readFileSync(defaultConfigPath, 'utf-8'));
    fs.writeFileSync(userConfigPath, JSON.stringify(config, null, 2), 'utf-8');
    return config;
}

function buildConfig(configDir, options) {
    const config = getOrCreateConfig(configDir);
    config.EgressRegion = options.region || '';

    if (options.protocol === 'conduit') {
        config.LimitTunnelProtocols = CONDUIT_PROTOCOLS;
    } else if (options.protocol === 'direct') {
        config.LimitTunnelProtocols = DIRECT_PROTOCOLS;
    } else {
        delete config.LimitTunnelProtocols;
    }

    const configPath = path.join(configDir, 'psiphon.config');
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf-8');
    return configPath;
}

function promptProtocol(rl) {
    return new Promise((resolve) => {
        console.log('\n  Connection protocol:');
        console.log('    1) auto    - Let Psiphon choose');
        console.log('    2) conduit - Via volunteer stations');
        console.log('    3) direct  - To Psiphon servers');
        rl.question('\n  Select (1/2/3): ', (answer) => {
            const trimmed = (answer || '1').trim().toLowerCase();
            if (trimmed === '2' || trimmed === 'conduit') {
                resolve('conduit');
            } else if (trimmed === '3' || trimmed === 'direct') {
                resolve('direct');
            } else {
                resolve('auto');
            }
        });
    });
}

function promptRunAgain(rl) {
    return new Promise((resolve) => {
        rl.question('\n  Change settings and run again? (y/n): ', (answer) => {
            resolve((answer || 'n').trim().toLowerCase() === 'y' || (answer || 'n').trim().toLowerCase() === 'yes');
        });
    });
}

function runTunnel(configDir, corePath, protocol) {
    return new Promise((resolve) => {
        const child = spawn(corePath, ['-config', 'psiphon.config'], {
            cwd: configDir,
            stdio: ['ignore', 'pipe', 'pipe']
        });

        child.stdout.on('data', (data) => {
            process.stdout.write(data.toString());
        });
        child.stderr.on('data', (data) => {
            process.stderr.write(data.toString());
        });

        const cleanupStdin = () => {
            if (process.stdin.isTTY) {
                process.stdin.removeListener('data', onKey);
                process.stdin.setRawMode(false);
                process.stdin.pause();
            }
        };

        const onKey = (key) => {
            if (key === 'q' || key === 'Q' || key === '\u0003') {
                cleanupStdin();
                console.log('\n\nStopping...');
                child.kill('SIGTERM');
            }
        };

        child.on('error', (err) => {
            console.error('\nFailed to start:', err.message);
            cleanupStdin();
            resolve();
        });

        child.on('close', (code, signal) => {
            cleanupStdin();
            if (signal) {
                console.log(`\nStopped (signal ${signal})`);
            } else if (code !== 0) {
                console.log(`\nProcess exited with code ${code}`);
            }
            resolve();
        });

        if (process.stdin.isTTY) {
            process.stdin.setRawMode(true);
            process.stdin.resume();
            process.stdin.setEncoding('utf8');
            process.stdin.on('data', onKey);
        }

        console.log('\n  --- Psiphon running (protocol: ' + protocol + ') ---');
        console.log('  HTTP proxy:  127.0.0.1:8081');
        console.log('  SOCKS proxy: 127.0.0.1:1081');
        console.log('  Press q to stop\n');
    });
}

async function runApp(options) {
    const configDir = options.configDir || DEFAULT_CONFIG_DIR;
    const corePath = options.core || DEFAULT_CORE_PATH;

    if (!fs.existsSync(corePath)) {
        console.error(`Error: psiphon-tunnel-core not found at ${corePath}`);
        process.exit(1);
    }

    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

    let runAgain = true;
    while (runAgain) {
        const protocol = await promptProtocol(rl);
        ensureConfigDir(configDir);
        buildConfig(configDir, { protocol, region: options.region || '' });

        console.log(`\n  Starting Psiphon (protocol: ${protocol})...\n`);
        await runTunnel(configDir, corePath, protocol);

        runAgain = await promptRunAgain(rl);
    }

    rl.close();
    console.log('\n  Goodbye.\n');
    process.exit(0);
}

program
    .name('psiphon-cli')
    .description('Interactive Psiphon tunnel (Conduit, Direct, or Auto)')
    .version('1.0.0');

program
    .command('run', { isDefault: true })
    .description('Run Psiphon (interactive: choose protocol, press q to stop)')
    .option('-c, --config-dir <dir>', 'config directory', DEFAULT_CONFIG_DIR)
    .option('--core <path>', 'path to psiphon-tunnel-core binary', DEFAULT_CORE_PATH)
    .option('-r, --region <code>', 'egress region (ISO country code)', '')
    .action((options) => {
        runApp(options);
    });

program
    .command('stop')
    .description('Stop the Psiphon tunnel')
    .action(() => {
        const { execSync } = require('child_process');
        try {
            execSync(`pkill -f ${PSIPHON_BIN}`, { stdio: 'ignore' });
            console.log('Psiphon tunnel stopped.');
        } catch (e) {
            if (e.status === 1) {
                console.log('No Psiphon tunnel process found.');
            } else {
                console.error('Error:', e.message);
                process.exit(1);
            }
        }
    });

program.parse();
