namespace PsiphonCliGui {
    public errordomain ConfigError {
        DEFAULT_CONFIG_MISSING,
        INVALID_UPSTREAM_PROXY,
        READ_FAILED,
        WRITE_FAILED
    }

    public class ConfigService : Object {
        public string config_dir { get; set; }

        public ConfigService () {
            config_dir = Constants.default_config_dir ();
        }

        public void apply_config_dir (string custom_dir) {
            string trimmed = custom_dir.strip ();
            if (trimmed.length > 0) {
                config_dir = trimmed;
            } else {
                config_dir = Constants.default_config_dir ();
            }
        }

        public string config_path () {
            return Path.build_filename (config_dir, Constants.CONFIG_FILE);
        }

        public string pid_path () {
            return Path.build_filename (config_dir, Constants.PID_FILE);
        }

        public string stats_path () {
            return Path.build_filename (config_dir, Constants.STATS_FILE);
        }

        public string log_path () {
            return Path.build_filename (config_dir, Constants.LOG_FILE);
        }

        public void ensure_config_dir () throws Error {
            DirUtils.create_with_parents (config_dir, 0755);
        }

        public void ensure_seed_files () throws Error {
            ensure_config_dir ();

            string default_config_path = find_default_asset (Constants.CONFIG_FILE);
            string user_config_path = config_path ();

            if (!FileUtils.test (user_config_path, FileTest.EXISTS)) {
                copy_file (default_config_path, user_config_path);
            }

            seed_server_list (user_config_path);
        }

        public string build_config (TunnelOptions options) throws Error {
            apply_config_dir (options.config_dir);
            ensure_seed_files ();
            ensure_server_list_ready ();

            string contents;
            FileUtils.get_contents (config_path (), out contents);

            var parser = new Json.Parser ();
            parser.load_from_data (contents, contents.length);

            Json.Object root = parser.get_root ().get_object ();
            root.set_string_member ("EgressRegion", options.region.strip ());
            root.set_boolean_member ("EmitBytesTransferred", true);

            if (options.enable_timeout) {
                root.remove_member ("EstablishTunnelTimeoutSeconds");
            } else {
                root.set_int_member ("EstablishTunnelTimeoutSeconds", 0);
            }

            if (options.enable_lan) {
                root.set_string_member ("ListenInterface", "any");
            } else {
                root.remove_member ("ListenInterface");
            }

            if (options.enable_beast_mode) {
                root.set_boolean_member ("AggressiveEstablishment", true);
            } else {
                root.remove_member ("AggressiveEstablishment");
            }

            root.remove_member ("LimitTunnelProtocols");
            if (options.protocol == ProtocolMode.CONDUIT) {
                root.set_array_member ("LimitTunnelProtocols", protocol_array (Constants.conduit_protocols ()));
            } else if (options.protocol == ProtocolMode.DIRECT) {
                root.set_array_member ("LimitTunnelProtocols", protocol_array (Constants.direct_protocols ()));
            }

            string upstream_proxy_url = options.upstream_proxy_url.strip ();
            if (upstream_proxy_url.length > 0) {
                validate_upstream_proxy_url (upstream_proxy_url);
                root.set_string_member ("UpstreamProxyURL", upstream_proxy_url);
            } else {
                root.remove_member ("UpstreamProxyURL");
            }

            if (!root.has_member ("RemoteServerListUrl") ||
                !root.has_member ("RemoteServerListSignaturePublicKey")) {
                warning ("RemoteServerListUrl/RemoteServerListSignaturePublicKey are not set in psiphon.config; official server list will not be used.");
            }

            var generator = new Json.Generator ();
            generator.pretty = true;
            generator.set_root (parser.get_root ());
            string output = generator.to_data (null);
            FileUtils.set_contents (config_path (), output);
            return config_path ();
        }

        public string resolve_core_path (string custom_path) {
            string trimmed = custom_path.strip ();
            if (trimmed.length > 0 && FileUtils.test (trimmed, FileTest.IS_EXECUTABLE)) {
                return trimmed;
            }

            string from_settings = read_core_path_setting ();
            if (from_settings.length > 0 && FileUtils.test (from_settings, FileTest.IS_EXECUTABLE)) {
                return from_settings;
            }

            string? from_path = Environment.find_program_in_path (Constants.PSIPHON_BIN);
            if (from_path != null && from_path.length > 0) {
                return from_path;
            }

            string[] candidates = {
                Path.build_filename (Environment.get_current_dir (), "..", Constants.PSIPHON_BIN),
                Path.build_filename (Environment.get_current_dir (), Constants.PSIPHON_BIN),
                Path.build_filename (Environment.get_current_dir (), "..", "..", Constants.PSIPHON_BIN),
                "/usr/local/bin/%s".printf (Constants.PSIPHON_BIN),
                "/usr/bin/%s".printf (Constants.PSIPHON_BIN)
            };

            foreach (string candidate in RuntimePaths.installed_core_path_candidates ()) {
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

        private void seed_server_list (string user_config_path) {
            try {
                string list_filename = resolve_server_list_filename (user_config_path);
                string default_list_path = find_default_server_list_asset ();
                string user_list_path = Path.build_filename (config_dir, list_filename);

                if (should_seed_server_list (user_list_path, default_list_path)) {
                    copy_file (default_list_path, user_list_path);
                }
            } catch (Error err) {
                warning ("Could not seed server list: %s", err.message);
            }
        }

        private void ensure_server_list_ready () throws Error {
            string list_filename = resolve_server_list_filename (config_path ());
            string user_list_path = Path.build_filename (config_dir, list_filename);

            if (!FileUtils.test (user_list_path, FileTest.EXISTS)) {
                throw new ConfigError.DEFAULT_CONFIG_MISSING (
                    "Server list '%s' was not found in %s. Install the GUI package assets or use Settings → Refresh server list.",
                    list_filename,
                    config_dir
                );
            }

            int64 list_size = query_file_size (user_list_path);
            if (list_size <= 0) {
                throw new ConfigError.DEFAULT_CONFIG_MISSING (
                    "Server list '%s' in %s is empty. Use Settings → Refresh server list or reinstall the package.",
                    list_filename,
                    config_dir
                );
            }
        }

        private string resolve_server_list_filename (string config_file_path) throws Error {
            string contents;
            FileUtils.get_contents (config_file_path, out contents);

            var parser = new Json.Parser ();
            parser.load_from_data (contents, contents.length);
            Json.Object root = parser.get_root ().get_object ();

            if (root.has_member ("RemoteServerListDownloadFilename")) {
                string filename = root.get_string_member ("RemoteServerListDownloadFilename").strip ();
                if (filename.length > 0) {
                    return filename;
                }
            }

            return Constants.SERVER_LIST_FILE;
        }

        private bool should_seed_server_list (string user_list_path, string default_list_path) {
            if (!FileUtils.test (user_list_path, FileTest.EXISTS)) {
                return true;
            }

            try {
                int64 user_size = query_file_size (user_list_path);
                if (user_size <= 0) {
                    return true;
                }

                int64 default_size = query_file_size (default_list_path);
                if (default_size > 1024 && user_size < default_size / 4) {
                    return true;
                }
            } catch (Error err) {
                warning ("Could not inspect server list sizes: %s", err.message);
                return true;
            }

            return false;
        }

        private string find_default_server_list_asset () throws Error {
            try {
                return find_default_asset (Constants.SERVER_LIST_FILE);
            } catch (Error err) {
                return find_default_asset ("server_list_compressed");
            }
        }

        private string find_default_asset (string name) throws Error {
            foreach (string dir in RuntimePaths.config_dir_candidates ()) {
                string candidate = Path.build_filename (dir, name);
                if (FileUtils.test (candidate, FileTest.EXISTS)) {
                    return candidate;
                }
            }

            throw new ConfigError.DEFAULT_CONFIG_MISSING (
                "Default asset '%s' was not found. Run from the portable bundle or install the GUI assets.",
                name
            );
        }

        private int64 query_file_size (string path) throws Error {
            var file = File.new_for_path (path);
            FileInfo info = file.query_info ("standard::size", FileQueryInfoFlags.NONE);
            return info.get_size ();
        }

        private void copy_file (string source, string dest) throws Error {
            var source_file = File.new_for_path (source);
            var dest_file = File.new_for_path (dest);
            source_file.copy (dest_file, FileCopyFlags.OVERWRITE, null, null);
        }

        private Json.Array protocol_array (string[] protocols) {
            var array = new Json.Array ();
            foreach (string protocol in protocols) {
                array.add_string_element (protocol);
            }
            return array;
        }

        private void validate_upstream_proxy_url (string url) throws Error {
            try {
                var parsed = Uri.parse (url, UriFlags.NONE);
                string scheme = parsed.get_scheme ();
                if (scheme != "http" && scheme != "https" && scheme != "socks5") {
                    throw new ConfigError.INVALID_UPSTREAM_PROXY (
                        "Upstream proxy URL must use http, https, or socks5."
                    );
                }
            } catch (UriError err) {
                throw new ConfigError.INVALID_UPSTREAM_PROXY (
                    "Upstream proxy URL is not a valid URL."
                );
            }
        }

        private string read_core_path_setting () {
            SettingsSchemaSource? source = SettingsSchemaSource.get_default ();
            if (source == null) {
                return "";
            }

            SettingsSchema? schema = source.lookup (Constants.SETTINGS_SCHEMA_ID, true);
            if (schema == null) {
                return "";
            }

            var settings = new Settings (Constants.SETTINGS_SCHEMA_ID);
            return settings.get_string ("core-path").strip ();
        }
    }
}
