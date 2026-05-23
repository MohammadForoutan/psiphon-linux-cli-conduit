int main (string[] args) {
    PsiphonCliGui.GSettingsSetup.ensure_local_schema ();
    Adw.init ();
    var app = new PsiphonCliGui.App ();
    return app.run (args);
}
