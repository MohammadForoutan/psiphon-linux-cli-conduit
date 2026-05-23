namespace PsiphonCliGui {
    public class SettingsDialog : Adw.Dialog {
        public signal void settings_saved (TunnelOptions options);

        private SettingsService settings_service;
        private ServerListService server_list_service;
        private Adw.ToastOverlay toast_overlay;
        private weak Gtk.Window? parent_window;

        private Adw.ComboRow protocol_row;
        private Adw.ComboRow region_row;
        private Adw.EntryRow upstream_proxy_row;
        private Adw.EntryRow core_path_row;
        private Adw.EntryRow config_dir_row;
        private Adw.SwitchRow lan_row;
        private Adw.SwitchRow timeout_row;
        private Region[] regions;

        public SettingsDialog (
            SettingsService settings_service,
            ServerListService server_list_service
        ) {
            Object (title: "Connection settings", content_width: 540, content_height: 640);

            this.settings_service = settings_service;
            this.server_list_service = server_list_service;
            regions = Region.all ();

            toast_overlay = new Adw.ToastOverlay ();
            set_child (toast_overlay);

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            toast_overlay.set_child (root);

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.vexpand = true;
            root.append (scrolled);

            var prefs = new Adw.PreferencesPage ();
            scrolled.set_child (prefs);

            var general = new Adw.PreferencesGroup ();
            general.title = "Connection";
            general.description = "Protocol, region, and proxy options used on connect.";
            prefs.add (general);

            protocol_row = new Adw.ComboRow ();
            protocol_row.title = "Protocol";
            protocol_row.subtitle = "Auto, Conduit, or Direct";
            protocol_row.model = new Gtk.StringList ({ "Auto", "Conduit", "Direct" });
            general.add (protocol_row);

            region_row = new Adw.ComboRow ();
            region_row.title = "Region";
            region_row.subtitle = "Egress country for the tunnel";
            region_row.model = new Gtk.StringList (build_region_items ());
            general.add (region_row);

            upstream_proxy_row = new Adw.EntryRow ();
            upstream_proxy_row.title = "Upstream proxy";
            upstream_proxy_row.text = "";
            general.add (upstream_proxy_row);

            var advanced = new Adw.PreferencesGroup ();
            advanced.title = "Advanced";
            advanced.description = "Core binary, config directory, and tunnel behavior.";
            prefs.add (advanced);

            core_path_row = new Adw.EntryRow ();
            core_path_row.title = "Core path";
            var core_browse = new Gtk.Button.from_icon_name ("folder-open-symbolic");
            core_browse.valign = Gtk.Align.CENTER;
            core_browse.tooltip_text = "Browse for psiphon-tunnel-core";
            core_browse.clicked.connect (() => browse_core_path.begin ());
            core_path_row.add_suffix (core_browse);
            advanced.add (core_path_row);

            config_dir_row = new Adw.EntryRow ();
            config_dir_row.title = "Config directory";
            var config_browse = new Gtk.Button.from_icon_name ("folder-open-symbolic");
            config_browse.valign = Gtk.Align.CENTER;
            config_browse.tooltip_text = "Browse for config directory";
            config_browse.clicked.connect (() => browse_config_dir.begin ());
            config_dir_row.add_suffix (config_browse);
            advanced.add (config_dir_row);

            lan_row = new Adw.SwitchRow ();
            lan_row.title = "Enable LAN";
            lan_row.subtitle = "Listen on 0.0.0.0 instead of 127.0.0.1";
            advanced.add (lan_row);

            timeout_row = new Adw.SwitchRow ();
            timeout_row.title = "Enable timeout";
            timeout_row.subtitle = "Use the establish-tunnel timeout from psiphon.config";
            advanced.add (timeout_row);

            var actions = new Adw.PreferencesGroup ();
            actions.title = "Maintenance";
            prefs.add (actions);

            var refresh_button = new Gtk.Button.with_label ("Refresh");
            refresh_button.valign = Gtk.Align.CENTER;
            refresh_button.clicked.connect (() => refresh_server_list.begin ());
            var refresh_row = new Adw.ActionRow ();
            refresh_row.title = "Server list";
            refresh_row.subtitle = "Download the latest official Psiphon server list.";
            refresh_row.activatable_widget = refresh_button;
            actions.add (refresh_row);

            var footer = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            footer.margin_top = 12;
            footer.margin_bottom = 12;
            footer.margin_start = 12;
            footer.margin_end = 12;
            footer.halign = Gtk.Align.END;

            var cancel_button = new Gtk.Button.with_label ("Cancel");
            cancel_button.clicked.connect (() => close ());
            footer.append (cancel_button);

            var save_button = new Gtk.Button.with_label ("Save");
            save_button.add_css_class ("suggested-action");
            save_button.clicked.connect (() => save_and_close ());
            footer.append (save_button);
            root.append (footer);
        }

        public void open (Gtk.Window parent) {
            parent_window = parent;
            load_from_settings ();
            present (parent);
        }

        private void load_from_settings () {
            var options = settings_service.load_options ();
            protocol_row.selected = (uint) options.protocol;
            select_region (options.region);
            upstream_proxy_row.text = options.upstream_proxy_url;
            core_path_row.text = options.core_path;
            config_dir_row.text = options.config_dir.length > 0
                ? options.config_dir
                : Constants.default_config_dir ();
            lan_row.active = options.enable_lan;
            timeout_row.active = options.enable_timeout;
        }

        private void save_and_close () {
            var options = build_options ();
            settings_service.save_options (options);
            settings_saved (options);
            close ();
        }

        private TunnelOptions build_options () {
            var options = new TunnelOptions ();
            options.protocol = ProtocolMode.from_index (protocol_row.selected);
            options.region = selected_region_code ();
            options.upstream_proxy_url = upstream_proxy_row.text.strip ();
            options.core_path = core_path_row.text.strip ();
            string config_dir = config_dir_row.text.strip ();
            if (config_dir == Constants.default_config_dir ()) {
                config_dir = "";
            }
            options.config_dir = config_dir;
            options.enable_lan = lan_row.active;
            options.enable_timeout = timeout_row.active;
            return options;
        }

        private async void browse_core_path () {
            if (parent_window == null) {
                return;
            }

            var dialog = new Gtk.FileDialog ();
            dialog.title = "Select psiphon-tunnel-core";

            try {
                File file = yield dialog.open (parent_window, null);
                core_path_row.text = file.get_path ();
            } catch (Error err) {
                if (err is IOError.CANCELLED) {
                    return;
                }
                toast_overlay.add_toast (new Adw.Toast (err.message));
            }
        }

        private async void browse_config_dir () {
            if (parent_window == null) {
                return;
            }

            var dialog = new Gtk.FileDialog ();
            dialog.title = "Select config directory";

            try {
                File folder = yield dialog.select_folder (parent_window, null);
                config_dir_row.text = folder.get_path ();
            } catch (Error err) {
                if (err is IOError.CANCELLED) {
                    return;
                }
                toast_overlay.add_toast (new Adw.Toast (err.message));
            }
        }

        private async void refresh_server_list () {
            try {
                string path = yield server_list_service.refresh_server_list ();
                toast_overlay.add_toast (new Adw.Toast ("Server list saved to %s".printf (path)));
            } catch (Error err) {
                toast_overlay.add_toast (new Adw.Toast (err.message));
            }
        }

        private string selected_region_code () {
            uint selected = region_row.selected;
            if (selected == 0) {
                return "";
            }

            int index = (int) selected - 1;
            if (index >= 0 && index < regions.length) {
                return regions[index].code;
            }

            return "";
        }

        private void select_region (string code) {
            if (code.length == 0) {
                region_row.selected = 0;
                return;
            }

            for (int i = 0; i < regions.length; i++) {
                if (regions[i].code == code) {
                    region_row.selected = (uint) (i + 1);
                    return;
                }
            }
        }

        private string[] build_region_items () {
            string[] items = { "Auto" };
            foreach (Region region in regions) {
                items += region.display_name_with_flag ();
            }
            return items;
        }
    }
}
