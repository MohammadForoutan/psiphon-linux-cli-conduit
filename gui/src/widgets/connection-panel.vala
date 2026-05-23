namespace PsiphonCliGui {
    public class ConnectionPanel : Gtk.Box {
        public signal void connect_requested ();
        public signal void disconnect_requested ();
        public signal void logs_requested ();

        private Gtk.Button connect_button;
        private Gtk.Button logs_button;
        private Gtk.Label status_label;
        private Gtk.Label ip_label;
        private bool running = false;

        public ConnectionPanel () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 12);
            halign = Gtk.Align.CENTER;
            margin_top = 12;
            margin_bottom = 12;

            var actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 18);
            actions.halign = Gtk.Align.CENTER;
            append (actions);

            connect_button = new Gtk.Button ();
            connect_button.add_css_class ("circular");
            connect_button.add_css_class ("suggested-action");
            connect_button.set_icon_name ("network-vpn-symbolic");
            connect_button.tooltip_text = "Connect";
            connect_button.width_request = 96;
            connect_button.height_request = 96;
            connect_button.clicked.connect (() => {
                if (running) {
                    disconnect_requested ();
                } else {
                    connect_requested ();
                }
            });
            actions.append (connect_button);

            logs_button = new Gtk.Button ();
            logs_button.add_css_class ("circular");
            logs_button.set_icon_name ("text-x-generic-symbolic");
            logs_button.tooltip_text = "View logs";
            logs_button.width_request = 72;
            logs_button.height_request = 72;
            logs_button.clicked.connect (() => logs_requested ());
            actions.append (logs_button);

            status_label = new Gtk.Label ("Ready to connect");
            status_label.add_css_class ("title-4");
            status_label.halign = Gtk.Align.CENTER;
            append (status_label);

            ip_label = new Gtk.Label ("");
            ip_label.add_css_class ("dim-label");
            ip_label.halign = Gtk.Align.CENTER;
            ip_label.selectable = true;
            append (ip_label);
        }

        public void set_running (bool running) {
            this.running = running;

            if (running) {
                connect_button.remove_css_class ("suggested-action");
                connect_button.add_css_class ("destructive-action");
                connect_button.set_icon_name ("network-offline-symbolic");
                connect_button.tooltip_text = "Disconnect";
                status_label.label = "Connecting...";
                ip_label.label = "";
            } else {
                connect_button.remove_css_class ("destructive-action");
                connect_button.add_css_class ("suggested-action");
                connect_button.set_icon_name ("network-vpn-symbolic");
                connect_button.tooltip_text = "Connect";
                status_label.label = "Ready to connect";
                ip_label.label = "";
            }
        }

        public void update_status (TunnelStats stats) {
            if (!running) {
                return;
            }

            if (stats.status == "connected") {
                double seconds = stats.connect_duration_ms / 1000.0;
                status_label.label = "Connected in %.1fs".printf (seconds);

                string flag = RegionFlags.flag_for_code (stats.egress_region);
                if (stats.public_ip != "-" && stats.public_ip.length > 0) {
                    ip_label.label = "%s %s".printf (flag, stats.public_ip);
                } else if (flag.length > 0) {
                    ip_label.label = "%s %s".printf (flag, stats.egress_region);
                } else {
                    ip_label.label = stats.egress_region;
                }
            } else if (stats.status == "connecting") {
                status_label.label = "Connecting...";
                ip_label.label = "";
            } else if (stats.status == "disconnecting" || stats.status == "exiting") {
                status_label.label = "Disconnecting...";
                ip_label.label = "";
            }
        }
    }
}
