namespace PsiphonCliGui {
    public class TunnelManager : Object {
        public signal void stats_changed (TunnelStats stats);
        public signal void running_changed (bool running);
        public signal void error (string message);
        public signal void log_line (string line);
        public signal void sing_box_error_changed (string message);

        private ConfigService config;
        private StatsService stats_service;
        private LogService log_service;
        private IpService ip_service;
        private NoticeParser parser;
        private SystemProxyService system_proxy;
        private SingBoxManager sing_box;
        private Subprocess? process = null;
        private TunnelStats stats = new TunnelStats ();
        private TunnelOptions? current_options = null;
        private uint stats_timer_id = 0;
        private bool ip_fetch_started = false;
        private bool routing_started = false;
        private string proxy_host = "127.0.0.1";

        public bool is_running {
            get { return process != null; }
        }

        public TunnelManager (
            ConfigService config,
            StatsService stats_service,
            LogService log_service,
            IpService ip_service
        ) {
            this.config = config;
            this.stats_service = stats_service;
            this.log_service = log_service;
            this.ip_service = ip_service;
            this.parser = new NoticeParser ();
            this.system_proxy = new SystemProxyService ();
            this.sing_box = new SingBoxManager (config);
            this.sing_box.diagnostic.connect ((line) => {
                string formatted = "[sing-box] %s".printf (line);
                log_service.append_line (formatted);
                log_line (formatted);
                if (is_sing_box_error_line (line)) {
                    sing_box_error_changed (line);
                }
            });

            ip_service.ip_fetched.connect ((ip) => {
                stats.public_ip = ip;
                stats_changed (stats.copy ());
            });
        }

        public string sing_box_log_text () {
            return sing_box.log_text;
        }

        public string sing_box_last_error () {
            return sing_box.last_error_message;
        }

        public void start_tunnel (TunnelOptions options) {
            if (is_running) {
                return;
            }

            current_options = options;

            try {
                config.build_config (options);
            } catch (Error err) {
                error (err.message);
                return;
            }

            string core_path = config.resolve_core_path (options.core_path);
            if (core_path.length == 0) {
                error ("psiphon-tunnel-core-x86_64 was not found. Put it in the repository root, install it on PATH, or set a custom core path.");
                return;
            }

            if (options.enable_tun && sing_box.resolve_path (options.sing_box_path).length == 0) {
                error ("sing-box was not found. Run npm run download-sing-box, add it to PATH, or set a custom sing-box path.");
                return;
            }

            proxy_host = options.enable_lan ? "0.0.0.0" : "127.0.0.1";
            int64 started_at = now_ms ();
            ip_fetch_started = false;
            routing_started = false;
            stats = new TunnelStats ();
            stats.protocol = options.protocol.config_value ();
            stats.status = "connecting";
            stats.http_proxy = "%s:%d".printf (proxy_host, Constants.HTTP_PROXY_PORT);
            stats.socks_proxy = "%s:%d".printf (proxy_host, Constants.SOCKS_PROXY_PORT);
            stats.beast_mode = options.enable_beast_mode ? "enabled" : "-";
            stats.routing_status = pending_routing_status (options);
            stats.started_at_ms = started_at;
            log_service.start_session ();

            try {
                var launcher = new SubprocessLauncher (
                    SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE
                );
                launcher.set_cwd (config.config_dir);
                process = launcher.spawn (core_path, "-config", config.config_path ());

                string? identifier = process.get_identifier ();
                if (identifier != null) {
                    FileUtils.set_contents (config.pid_path (), identifier);
                }

                DataInputStream stdout_stream = new DataInputStream (process.get_stdout_pipe ());
                DataInputStream stderr_stream = new DataInputStream (process.get_stderr_pipe ());
                read_stream.begin (stdout_stream);
                read_stream.begin (stderr_stream);

                process.wait_async.begin (null, (obj, res) => {
                    try {
                        process.wait_async.end (res);
                    } catch (Error err) {
                        warning ("Could not wait for tunnel process: %s", err.message);
                    }
                    cleanup_after_exit ();
                });

                stats_timer_id = Timeout.add (Constants.STATS_UPDATE_MS, () => {
                    stats.uptime_ms = now_ms () - stats.started_at_ms;
                    stats_service.write_stats (stats);
                    stats_changed (stats.copy ());
                    return is_running;
                });

                stats_changed (stats.copy ());
                running_changed (true);
            } catch (Error err) {
                process = null;
                error ("Failed to start psiphon-tunnel-core: %s".printf (err.message));
                cleanup_files ();
            }
        }

        public void stop_tunnel () {
            stop_routing ();

            if (process != null) {
                process.send_signal (15);
                return;
            }

            fallback_disconnect ();
        }

        private async void read_stream (DataInputStream stream) {
            try {
                while (is_running) {
                    size_t length = 0;
                    string? line = yield stream.read_line_async (Priority.DEFAULT, null, out length);
                    if (line == null) {
                        break;
                    }

                    log_service.append_line (line);
                    log_line (line);

                    if (parser.apply_line (line, stats, proxy_host)) {
                        handle_stats_update ();
                    }
                }
            } catch (Error err) {
                warning ("Could not read tunnel output: %s", err.message);
            }
        }

        private void handle_stats_update () {
            if (stats.status == "connected" && stats.connected_at_ms == 0) {
                stats.connected_at_ms = now_ms ();
                stats.connect_duration_ms = stats.connected_at_ms - stats.started_at_ms;
                if (!ip_fetch_started) {
                    ip_fetch_started = true;
                    ip_service.fetch_public_ip.begin ("127.0.0.1", Constants.HTTP_PROXY_PORT);
                }
                start_routing ();
            }

            stats_changed (stats.copy ());
        }

        private void start_routing () {
            if (routing_started || current_options == null) {
                return;
            }

            if (!current_options.enable_system_proxy && !current_options.enable_tun) {
                return;
            }

            routing_started = true;
            string[] parts = {};

            if (current_options.enable_system_proxy) {
                try {
                    system_proxy.enable (stats.http_proxy, stats.socks_proxy);
                    parts += "System proxy active";
                } catch (Error err) {
                    parts += "System proxy failed";
                    error (err.message);
                }
            }

            if (current_options.enable_tun) {
                try {
                    sing_box.start (current_options.sing_box_path, stats.socks_proxy);
                    parts += "TUN active";
                    sing_box_error_changed ("");
                } catch (Error err) {
                    parts += "TUN failed";
                    sing_box_error_changed (err.message);
                    error (err.message);
                }
            }

            stats.routing_status = string.joinv (" · ", parts);
            stats_changed (stats.copy ());
        }

        private void stop_routing () {
            if (!routing_started && !system_proxy.is_active && !sing_box.is_running) {
                return;
            }

            system_proxy.disable ();
            sing_box.stop ();
            routing_started = false;

            if (current_options != null) {
                stats.routing_status = pending_routing_status (current_options);
            }
        }

        private void cleanup_after_exit () {
            stop_routing ();
            process = null;
            current_options = null;
            stats.status = "disconnected";
            stats.routing_status = "-";
            cleanup_files ();
            log_service.close_session ();
            if (stats_timer_id != 0) {
                Source.remove (stats_timer_id);
                stats_timer_id = 0;
            }
            stats_changed (stats.copy ());
            running_changed (false);
        }

        private void cleanup_files () {
            if (FileUtils.test (config.pid_path (), FileTest.EXISTS)) {
                FileUtils.remove (config.pid_path ());
            }
            stats_service.delete_stats ();
        }

        private void fallback_disconnect () {
            stop_routing ();

            try {
                if (FileUtils.test (config.pid_path (), FileTest.EXISTS)) {
                    string pid;
                    FileUtils.get_contents (config.pid_path (), out pid);
                    Process.spawn_command_line_sync ("kill -TERM %s".printf (pid.strip ()));
                    cleanup_files ();
                    log_service.close_session ();
                    running_changed (false);
                    return;
                }

                Process.spawn_command_line_sync ("pkill -f %s".printf (Constants.PSIPHON_BIN));
                cleanup_files ();
                log_service.close_session ();
                running_changed (false);
            } catch (Error err) {
                error ("Failed to disconnect: %s".printf (err.message));
            }
        }

        private string pending_routing_status (TunnelOptions options) {
            string[] parts = {};

            if (options.enable_system_proxy) {
                parts += "System proxy pending";
            }
            if (options.enable_tun) {
                parts += "TUN pending";
            }

            if (parts.length == 0) {
                return "-";
            }

            return string.joinv (" · ", parts);
        }

        private int64 now_ms () {
            return GLib.get_real_time () / 1000;
        }

        private bool is_sing_box_error_line (string line) {
            string lower = line.down ();
            return lower.contains ("fatal") ||
                lower.contains ("error") ||
                lower.contains ("legacy") ||
                lower.contains ("failed") ||
                lower.contains ("rejected") ||
                lower.contains ("exited:");
        }
    }
}
