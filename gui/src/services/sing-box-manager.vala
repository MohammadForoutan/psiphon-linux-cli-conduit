namespace PsiphonCliGui {
    public class SingBoxManager : Object {
        public signal void diagnostic (string line);

        private ConfigService config;
        private Subprocess? process = null;
        private bool running = false;
        private string last_error = "";
        private StringBuilder log_buffer = new StringBuilder ();

        public string last_error_message {
            get { return last_error; }
        }

        public string log_text {
            get { return log_buffer.str; }
        }

        public void clear_logs () {
            log_buffer = new StringBuilder ();
            last_error = "";
        }

        public bool is_running {
            get { return running; }
        }

        public SingBoxManager (ConfigService config) {
            this.config = config;
        }

        public string resolve_path (string custom_path) {
            string trimmed = custom_path.strip ();
            if (trimmed.length > 0 && FileUtils.test (trimmed, FileTest.IS_EXECUTABLE)) {
                return trimmed;
            }

            string from_settings = read_sing_box_path_setting ();
            if (from_settings.length > 0 && FileUtils.test (from_settings, FileTest.IS_EXECUTABLE)) {
                return from_settings;
            }

            string? from_path = Environment.find_program_in_path (Constants.SING_BOX_BIN);
            if (from_path != null && from_path.length > 0) {
                return from_path;
            }

            string[] candidates = {
                Path.build_filename (Environment.get_current_dir (), "..", Constants.SING_BOX_BIN),
                Path.build_filename (Environment.get_current_dir (), Constants.SING_BOX_BIN),
                Path.build_filename (Environment.get_current_dir (), "..", "..", Constants.SING_BOX_BIN),
                "/usr/local/bin/%s".printf (Constants.SING_BOX_BIN),
                "/usr/bin/%s".printf (Constants.SING_BOX_BIN)
            };

            foreach (string candidate in RuntimePaths.installed_sing_box_path_candidates ()) {
                if (FileUtils.test (candidate, FileTest.IS_EXECUTABLE)) {
                    return candidate;
                }
            }

            foreach (string candidate in candidates) {
                if (FileUtils.test (candidate, FileTest.IS_EXECUTABLE)) {
                    return candidate;
                }
            }

            return "";
        }

        public string config_path () {
            return Path.build_filename (config.config_dir, Constants.SING_BOX_CONFIG_FILE);
        }

        public string pid_path () {
            return Path.build_filename (config.config_dir, Constants.SING_BOX_PID_FILE);
        }

        public void start (string custom_path, string socks_endpoint) throws Error {
            if (running) {
                return;
            }

            string sing_box_path = resolve_path (custom_path);
            if (sing_box_path.length == 0) {
                throw new IOError.NOT_FOUND (
                    "sing-box was not found. Run npm run download-sing-box, install the RPM, or set a custom path."
                );
            }

            string socks_host;
            int socks_port;
            parse_endpoint (socks_endpoint, out socks_host, out socks_port);
            write_config (socks_host, socks_port);
            clear_logs ();

            string lib_path = library_path (sing_box_path);
            validate_config (sing_box_path, lib_path);

            try {
                var launcher = new SubprocessLauncher (
                    SubprocessFlags.STDERR_PIPE | SubprocessFlags.STDOUT_PIPE
                );
                apply_library_path (launcher, lib_path);
                process = launcher.spawn (
                    sing_box_path,
                    "run",
                    "-c",
                    config_path ()
                );

                string? identifier = process.get_identifier ();
                if (identifier != null) {
                    FileUtils.set_contents (pid_path (), identifier);
                }

                DataInputStream stderr_stream = new DataInputStream (process.get_stderr_pipe ());
                DataInputStream stdout_stream = new DataInputStream (process.get_stdout_pipe ());
                read_stream.begin (stderr_stream);
                read_stream.begin (stdout_stream);

                process.wait_async.begin (null, (obj, res) => {
                    try {
                        process.wait_async.end (res);
                    } catch (Error err) {
                        warning ("Could not wait for sing-box: %s", err.message);
                    }
                    cleanup_process (true);
                });

                running = true;
            } catch (Error err) {
                process = null;
                string detail = last_error.length > 0 ? last_error : err.message;
                throw new IOError.FAILED (
                    "Failed to start sing-box: %s. TUN mode may require CAP_NET_ADMIN on the sing-box binary (the RPM post-install script tries to set this).".printf (
                        detail
                    )
                );
            }
        }

        public void stop () {
            if (process != null) {
                process.send_signal (15);
                return;
            }

            fallback_stop ();
        }

        private void cleanup_process (bool notify_exit) {
            bool was_running = running;
            process = null;
            running = false;
            remove_pid_file ();

            if (notify_exit && was_running && last_error.length > 0) {
                diagnostic ("exited: %s".printf (last_error));
            }
        }

        private void fallback_stop () {
            try {
                if (FileUtils.test (pid_path (), FileTest.EXISTS)) {
                    string pid;
                    FileUtils.get_contents (pid_path (), out pid);
                    Process.spawn_command_line_sync ("kill -TERM %s".printf (pid.strip ()));
                    remove_pid_file ();
                    running = false;
                    return;
                }

                Process.spawn_command_line_sync ("pkill -f 'sing-box run'");
                remove_pid_file ();
                running = false;
            } catch (Error err) {
                warning ("Could not stop sing-box: %s", err.message);
            }
        }

        private void remove_pid_file () {
            if (FileUtils.test (pid_path (), FileTest.EXISTS)) {
                FileUtils.remove (pid_path ());
            }
        }

        private void validate_config (string sing_box_path, string lib_path) throws Error {
            var launcher = new SubprocessLauncher (SubprocessFlags.STDERR_PIPE);
            apply_library_path (launcher, lib_path);

            try {
                Subprocess check = launcher.spawn (sing_box_path, "check", "-c", config_path ());
                string? stdout_output = null;
                string? stderr_output = null;
                check.communicate_utf8 (null, null, out stdout_output, out stderr_output);
                if (check.get_exit_status () != 0) {
                    string detail = stderr_output != null ? stderr_output.strip () : "";
                    if (detail.length == 0) {
                        detail = "sing-box rejected the generated TUN config";
                    }
                    last_error = detail;
                    diagnostic (detail);
                    throw new IOError.FAILED (detail);
                }
            } catch (Error err) {
                if (err is IOError.FAILED) {
                    throw err;
                }
                throw new IOError.FAILED ("Could not validate sing-box config: %s".printf (err.message));
            }
        }

        private async void read_stream (DataInputStream stream) {
            try {
                while (running && process != null) {
                    size_t length = 0;
                    string? line = yield stream.read_line_async (Priority.DEFAULT, null, out length);
                    if (line == null) {
                        break;
                    }

                    string trimmed = line.strip ();
                    if (trimmed.length == 0) {
                        continue;
                    }

                    log_buffer.append (trimmed);
                    log_buffer.append_c ('\n');
                    if (is_error_line (trimmed)) {
                        last_error = trimmed;
                    }
                    diagnostic (trimmed);
                }
            } catch (Error err) {
                warning ("Could not read sing-box output: %s", err.message);
            }
        }

        private void write_config (string socks_host, int socks_port) throws Error {
            config.ensure_config_dir ();

            string json = """
{
  "log": {
    "level": "warn"
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-remote",
        "type": "udp",
        "server": "8.8.8.8",
        "detour": "psiphon"
      }
    ],
    "final": "dns-remote"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "%s",
      "address": [
        "172.19.0.1/30"
      ],
      "auto_route": true,
      "strict_route": true,
      "stack": "mixed"
    }
  ],
  "outbounds": [
    {
      "type": "socks",
      "tag": "psiphon",
      "server": "%s",
      "server_port": %d
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "inbound": "tun-in",
        "action": "sniff",
        "timeout": "1s"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "final": "psiphon",
    "auto_detect_interface": true
  }
}
""".printf (Constants.SING_BOX_TUN_INTERFACE, socks_host, socks_port);

            FileUtils.set_contents (config_path (), json);
        }

        private string library_path (string sing_box_path) {
            string sing_box_dir = Path.get_dirname (sing_box_path);
            string? existing_lib_path = Environment.get_variable ("LD_LIBRARY_PATH");
            if (existing_lib_path != null && existing_lib_path.length > 0) {
                return "%s:%s".printf (sing_box_dir, existing_lib_path);
            }
            return sing_box_dir;
        }

        private void apply_library_path (SubprocessLauncher launcher, string lib_path) {
            launcher.setenv ("LD_LIBRARY_PATH", lib_path, true);
        }

        private bool is_error_line (string line) {
            string lower = line.down ();
            return lower.contains ("fatal") ||
                lower.contains ("error") ||
                lower.contains ("legacy") ||
                lower.contains ("failed") ||
                lower.contains ("rejected");
        }

        private void parse_endpoint (string endpoint, out string host, out int port) {
            host = "127.0.0.1";
            port = Constants.SOCKS_PROXY_PORT;

            string[] parts = endpoint.split (":", 2);
            if (parts.length == 2) {
                host = parts[0].strip ();
                port = int.parse (parts[1].strip ());
            }

            if (host == "0.0.0.0") {
                host = "127.0.0.1";
            }
        }

        private string read_sing_box_path_setting () {
            SettingsSchemaSource? source = SettingsSchemaSource.get_default ();
            if (source == null) {
                return "";
            }

            SettingsSchema? schema = source.lookup (Constants.SETTINGS_SCHEMA_ID, true);
            if (schema == null) {
                return "";
            }

            var settings = new Settings (Constants.SETTINGS_SCHEMA_ID);
            return settings.get_string ("sing-box-path").strip ();
        }
    }
}
