namespace PsiphonCliGui {
    public errordomain ServerListError {
        CONFIG_MISSING,
        URL_MISSING,
        DOWNLOAD_FAILED
    }

    public class ServerListService : Object {
        private ConfigService config;

        public ServerListService (ConfigService config) {
            this.config = config;
        }

        public async string refresh_server_list () throws Error {
            config.ensure_seed_files ();

            string contents;
            FileUtils.get_contents (config.config_path (), out contents);

            var parser = new Json.Parser ();
            parser.load_from_data (contents, contents.length);
            Json.Object root = parser.get_root ().get_object ();

            if (!root.has_member ("RemoteServerListUrl")) {
                throw new ServerListError.URL_MISSING (
                    "RemoteServerListUrl is not set in psiphon.config."
                );
            }

            string url = root.get_string_member ("RemoteServerListUrl");
            string filename = "remote_server_list";
            if (root.has_member ("RemoteServerListDownloadFilename")) {
                filename = root.get_string_member ("RemoteServerListDownloadFilename");
            }

            string dest_path = Path.build_filename (config.config_dir, filename);
            string command = "curl -s --fail --max-time 60 -o '%s' '%s'".printf (
                dest_path.replace ("'", "'\\''"),
                url.replace ("'", "'\\''")
            );

            string? stdout;
            string? stderr;
            int exit_status;
            Process.spawn_command_line_sync (
                command,
                out stdout,
                out stderr,
                out exit_status
            );

            if (exit_status != 0) {
                throw new ServerListError.DOWNLOAD_FAILED (
                    stderr != null && stderr.length > 0 ? stderr.strip () : "Failed to download server list"
                );
            }

            return dest_path;
        }
    }
}
