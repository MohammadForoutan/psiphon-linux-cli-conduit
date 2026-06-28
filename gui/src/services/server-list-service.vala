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
            string[] argv = {
                "curl",
                "-s",
                "--fail",
                "--max-time",
                "60",
                "-o",
                dest_path,
                url
            };

            var launcher = new SubprocessLauncher (
                SubprocessFlags.STDERR_PIPE | SubprocessFlags.STDOUT_SILENCE
            );
            Subprocess subprocess = launcher.spawnv (argv);

            try {
                yield subprocess.wait_check_async (null);
            } catch (Error err) {
                string detail = yield read_subprocess_stderr (subprocess);
                if (detail.length > 0) {
                    throw new ServerListError.DOWNLOAD_FAILED (detail);
                }
                throw new ServerListError.DOWNLOAD_FAILED (
                    "Failed to download server list: %s".printf (err.message)
                );
            }

            return dest_path;
        }

        private async string read_subprocess_stderr (Subprocess subprocess) {
            try {
                var stream = new DataInputStream (subprocess.get_stderr_pipe ());
                size_t length = 0;
                string? line = yield stream.read_line_async (
                    Priority.DEFAULT,
                    null,
                    out length
                );
                if (line != null) {
                    return line.strip ();
                }
            } catch (Error err) {
                warning ("Could not read curl stderr: %s", err.message);
            }
            return "";
        }
    }
}
