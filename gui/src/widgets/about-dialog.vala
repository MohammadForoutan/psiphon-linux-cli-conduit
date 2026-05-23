namespace PsiphonCliGui {
    public class AboutDialogHelper {
        public static void present (Gtk.Window parent) {
            var info = VersionInfo.load ();

            var dialog = new Adw.AboutDialog ();
            dialog.application_name = "Psiphon CLI GUI";
            dialog.application_icon = "network-vpn-symbolic";
            dialog.version = info.version;
            dialog.comments = "Unofficial Psiphon VPN client for Linux. Not affiliated with Psiphon Inc.";
            dialog.website = "https://github.com/MohammadForoutan/psiphon-linux-cli-conduit";
            dialog.issue_url = "https://github.com/MohammadForoutan/psiphon-linux-cli-conduit/issues";
            dialog.developers = { "Mohammad Foroutan" };
            dialog.present (parent);
        }
    }
}
