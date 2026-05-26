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
}
