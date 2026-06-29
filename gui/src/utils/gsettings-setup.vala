namespace PsiphonCliGui.GSettingsSetup {
    public void ensure_local_schema () {
        if (Environment.get_variable ("GSETTINGS_SCHEMA_DIR") != null) {
            return;
        }

        string? schema_dir = RuntimePaths.find_schema_dir ();
        if (schema_dir != null) {
            Environment.set_variable ("GSETTINGS_SCHEMA_DIR", schema_dir, true);
        }
    }

    public void ensure_installed_core_path () {
        var settings = new Settings (Constants.SETTINGS_SCHEMA_ID);
        string current = settings.get_string ("core-path").strip ();
        if (current.length > 0 && FileUtils.test (current, FileTest.IS_EXECUTABLE)) {
            return;
        }

        foreach (string candidate in RuntimePaths.installed_core_path_candidates ()) {
            if (FileUtils.test (candidate, FileTest.IS_EXECUTABLE)) {
                settings.set_string ("core-path", candidate);
                return;
            }
        }
    }
}
