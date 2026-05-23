namespace PsiphonCliGui {
    public struct VersionData {
        public string version;
        public string package_version;
        public string commit;
        public string date;
    }

    public class VersionInfo {
        public static VersionData load () {
            foreach (string path in version_paths ()) {
                if (!FileUtils.test (path, FileTest.EXISTS)) {
                    continue;
                }

                try {
                    string contents;
                    FileUtils.get_contents (path, out contents);

                    var parser = new Json.Parser ();
                    parser.load_from_data (contents, contents.length);
                    Json.Object root = parser.get_root ().get_object ();

                    var data = VersionData ();
                    data.version = read_string (root, "version", "unknown");
                    data.package_version = read_string (root, "packageVersion", "");
                    data.commit = read_string (root, "commit", "");
                    data.date = read_string (root, "date", "");

                    if (data.version.length > 0) {
                        return data;
                    }
                } catch (Error err) {
                    warning ("Could not read version from %s: %s", path, err.message);
                }
            }

            return unknown ();
        }

        public static string display () {
            return load ().version;
        }

        private static VersionData unknown () {
            var data = VersionData ();
            data.version = "unknown";
            data.package_version = "";
            data.commit = "";
            data.date = "";
            return data;
        }

        private static string read_string (Json.Object root, string member, string fallback) {
            if (root.has_member (member)) {
                return root.get_string_member (member);
            }
            return fallback;
        }

        private static string[] version_paths () {
            string exe_path = "";
            try {
                exe_path = FileUtils.read_link ("/proc/self/exe");
            } catch (FileError e) {
                // ignore
            }

            string[] paths = {
                Path.build_filename (Environment.get_current_dir (), "version.json"),
                Path.build_filename (Environment.get_current_dir (), "build", "version.json"),
                Path.build_filename (Environment.get_current_dir (), "..", "cli", "version.generated.json"),
                Path.build_filename (Environment.get_current_dir (), "..", "..", "cli", "version.generated.json"),
                "/usr/local/share/psiphon-cli-gui/version.json",
                "/usr/share/psiphon-cli-gui/version.json"
            };

            if (exe_path.length > 0) {
                string exe_dir = Path.get_dirname (exe_path);
                paths += Path.build_filename (exe_dir, "version.json");
            }

            return paths;
        }
    }
}
