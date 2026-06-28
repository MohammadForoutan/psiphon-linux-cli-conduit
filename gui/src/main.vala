int main (string[] args) {
    PsiphonCliGui.GSettingsSetup.ensure_local_schema ();
    PsiphonCliGui.GSettingsSetup.ensure_installed_core_path ();
    Adw.init ();
    var app = new PsiphonCliGui.App ();
    return app.run (args);
}
