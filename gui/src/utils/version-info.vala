namespace PsiphonCliGui {
    public struct VersionData {
        public string version;
        public string package_version;
        public string commit;
        public string date;
    }

    public class VersionInfo {
        public static VersionData load () {
            foreach (string path in RuntimePaths.version_file_candidates ()) {
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
    }
}
