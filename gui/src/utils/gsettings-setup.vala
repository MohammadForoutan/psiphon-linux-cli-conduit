namespace PsiphonCliGui.GSettingsSetup {
    public void ensure_local_schema () {
        if (Environment.get_variable ("GSETTINGS_SCHEMA_DIR") != null) {
            return;
        }

        string exe_path;
        try {
            exe_path = FileUtils.read_link ("/proc/self/exe");
        } catch (FileError e) {
            return;
        }

        var schema_dir = Path.build_filename (Path.get_dirname (exe_path), "data");
        var compiled = Path.build_filename (schema_dir, "gschemas.compiled");
        if (FileUtils.test (compiled, FileTest.EXISTS)) {
            Environment.set_variable ("GSETTINGS_SCHEMA_DIR", schema_dir, true);
        }
    }
}
