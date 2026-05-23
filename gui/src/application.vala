namespace PsiphonCliGui {
    public class App : Adw.Application {
        private MainWindow? window = null;

        public App () {
            Object (
                application_id: Constants.APPLICATION_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
        }

        protected override void activate () {
            if (window == null) {
                window = new MainWindow (this);
            }
            window.present ();
        }
    }
}
