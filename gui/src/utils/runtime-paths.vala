namespace PsiphonCliGui.RuntimePaths {
    public string executable_path () {
        try {
            return FileUtils.read_link ("/proc/self/exe");
        } catch (FileError e) {
            return "";
        }
    }

    public string executable_dir () {
        string exe = executable_path ();
        if (exe.length == 0) {
            return "";
        }
        return Path.get_dirname (exe);
    }

    public string? find_schema_dir () {
        foreach (string candidate in schema_dir_candidates ()) {
            string compiled = Path.build_filename (candidate, "gschemas.compiled");
            if (FileUtils.test (compiled, FileTest.EXISTS)) {
                return candidate;
            }
        }
        return null;
    }

    public string[] config_dir_candidates () {
        string exe_dir = executable_dir ();
        string cwd = Environment.get_current_dir ();

        if (exe_dir.length > 0) {
            return {
                Path.build_filename (exe_dir, "configs"),
                Path.build_filename (exe_dir, "..", "configs"),
                Path.build_filename (exe_dir, "..", "share", "psiphon-cli-gui", "configs"),
                Path.build_filename (exe_dir, "..", "..", "share", "psiphon-cli-gui", "configs"),
                Path.build_filename (cwd, "configs"),
                Path.build_filename (cwd, "..", "configs"),
                Path.build_filename (cwd, "..", "..", "configs"),
                "/usr/local/share/psiphon-cli-gui/configs",
                "/usr/share/psiphon-cli-gui/configs"
            };
        }

        return {
            Path.build_filename (cwd, "configs"),
            Path.build_filename (cwd, "..", "configs"),
            Path.build_filename (cwd, "..", "..", "configs"),
            "/usr/local/share/psiphon-cli-gui/configs",
            "/usr/share/psiphon-cli-gui/configs"
        };
    }

    public string[] version_file_candidates () {
        string exe_dir = executable_dir ();
        string cwd = Environment.get_current_dir ();

        if (exe_dir.length > 0) {
            return {
                Path.build_filename (exe_dir, "version.json"),
                Path.build_filename (exe_dir, "..", "share", "psiphon-cli-gui", "version.json"),
                Path.build_filename (exe_dir, "..", "..", "share", "psiphon-cli-gui", "version.json"),
                Path.build_filename (cwd, "version.json"),
                Path.build_filename (cwd, "build", "version.json"),
                Path.build_filename (cwd, "..", "cli", "version.generated.json"),
                "/usr/local/share/psiphon-cli-gui/version.json",
                "/usr/share/psiphon-cli-gui/version.json"
            };
        }

        return {
            Path.build_filename (cwd, "version.json"),
            Path.build_filename (cwd, "build", "version.json"),
            Path.build_filename (cwd, "..", "cli", "version.generated.json"),
            "/usr/local/share/psiphon-cli-gui/version.json",
            "/usr/share/psiphon-cli-gui/version.json"
        };
    }

    private static string[] schema_dir_candidates () {
        string exe_dir = executable_dir ();

        if (exe_dir.length > 0) {
            return {
                Path.build_filename (exe_dir, "data"),
                Path.build_filename (exe_dir, "..", "data"),
                Path.build_filename (exe_dir, "..", "share", "glib-2.0", "schemas"),
                Path.build_filename (exe_dir, "..", "..", "share", "glib-2.0", "schemas"),
                "/usr/local/share/glib-2.0/schemas",
                "/usr/share/glib-2.0/schemas"
            };
        }

        return {
            "/usr/local/share/glib-2.0/schemas",
            "/usr/share/glib-2.0/schemas"
        };
    }
}
