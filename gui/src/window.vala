namespace PsiphonCliGui {
    public class MainWindow : Adw.ApplicationWindow {
        private ConfigService config;
        private ConnectionPanel connection_panel;
        private StatsPanel stats_panel;
        private Adw.ToastOverlay toast_overlay;
        private TunnelManager tunnel_manager;
        private SettingsService settings_service;
        private LogService log_service;
        private ServerListService server_list_service;
        private SettingsDialog? settings_dialog = null;
        private LogsWindow? logs_window = null;
        private TunnelOptions current_options;

        public MainWindow (Adw.Application app) {
            Object (application: app, title: "Psiphon CLI GUI");
            set_default_size (720, 640);

            config = new ConfigService ();
            settings_service = new SettingsService ();
            log_service = new LogService (config);
            var stats_service = new StatsService (config);
            server_list_service = new ServerListService (config);
            var ip_service = new IpService ();
            tunnel_manager = new TunnelManager (config, stats_service, log_service, ip_service);
            current_options = settings_service.load_options ();
            config.apply_config_dir (current_options.config_dir);

            toast_overlay = new Adw.ToastOverlay ();
            set_content (toast_overlay);

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            toast_overlay.set_child (root);

            var header = new Adw.HeaderBar ();

            var about_button = new Gtk.Button.from_icon_name ("help-about-symbolic");
            about_button.tooltip_text = "About";
            about_button.clicked.connect (open_about);
            header.pack_end (about_button);

            var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic");
            settings_button.tooltip_text = "Connection settings";
            settings_button.clicked.connect (open_settings);
            header.pack_end (settings_button);
            root.append (header);

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.vexpand = true;
            root.append (scrolled);

            var clamp = new Adw.Clamp ();
            clamp.maximum_size = 640;
            clamp.tightening_threshold = 480;
            clamp.margin_top = 18;
            clamp.margin_bottom = 18;
            clamp.margin_start = 18;
            clamp.margin_end = 18;
            scrolled.set_child (clamp);

            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 16);
            clamp.set_child (content);

            var intro = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            content.append (intro);

            var icon = new Gtk.Image.from_icon_name ("network-vpn-symbolic");
            icon.pixel_size = 36;
            icon.valign = Gtk.Align.CENTER;
            intro.append (icon);

            var intro_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            intro_text.valign = Gtk.Align.CENTER;
            intro_text.hexpand = true;
            intro.append (intro_text);

            var title = new Gtk.Label ("Psiphon CLI GUI");
            title.add_css_class ("title-2");
            title.halign = Gtk.Align.START;
            intro_text.append (title);

            var subtitle = new Gtk.Label ("Connect, view stats, and inspect tunnel logs.");
            subtitle.add_css_class ("dim-label");
            subtitle.halign = Gtk.Align.START;
            subtitle.wrap = true;
            intro_text.append (subtitle);

            connection_panel = new ConnectionPanel ();
            stats_panel = new StatsPanel ();
            content.append (connection_panel);
            content.append (stats_panel);

            connection_panel.connect_requested.connect (() => {
                tunnel_manager.start_tunnel (current_options);
            });
            connection_panel.disconnect_requested.connect (() => {
                tunnel_manager.stop_tunnel ();
            });
            connection_panel.logs_requested.connect (open_logs);

            tunnel_manager.running_changed.connect ((running) => {
                connection_panel.set_running (running);
                if (!running) {
                    stats_panel.show_disconnected ();
                }
            });

            tunnel_manager.stats_changed.connect ((stats) => {
                stats_panel.update_stats (stats);
                connection_panel.update_status (stats);
            });

            tunnel_manager.error.connect ((message) => {
                toast_overlay.add_toast (new Adw.Toast (message));
            });

            log_service.line_appended.connect ((line) => {
                if (logs_window != null) {
                    logs_window.append_line (line);
                }
            });
        }

        private void open_about () {
            AboutDialogHelper.present (this);
        }

        private void open_settings () {
            if (settings_dialog == null) {
                settings_dialog = new SettingsDialog (settings_service, server_list_service);
                settings_dialog.settings_saved.connect ((options) => {
                    current_options = options;
                    config.apply_config_dir (options.config_dir);
                });
            }

            settings_dialog.open (this);
        }

        private void open_logs () {
            if (logs_window == null) {
                logs_window = new LogsWindow (this);
            }

            logs_window.set_text (log_service.get_text ());
            logs_window.present ();
        }
    }
}
