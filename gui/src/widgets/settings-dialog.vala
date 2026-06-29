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
        private Adw.SwitchRow beast_mode_row;
        private Adw.SwitchRow timeout_row;
        private Adw.SwitchRow system_proxy_row;
        private Adw.SwitchRow tun_row;
        private Adw.EntryRow sing_box_path_row;
        private Adw.ActionRow refresh_row;
        private Gtk.Stack refresh_stack;
        private Gtk.Button refresh_button;
        private Gtk.Spinner refresh_spinner;
        private Gtk.Label refresh_busy_label;
        private bool refresh_in_progress = false;
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

            beast_mode_row = new Adw.SwitchRow ();
            beast_mode_row.title = "Beast mode";
            beast_mode_row.subtitle = "Aggressive establishment: try all protocols on all servers";
            general.add (beast_mode_row);

            var routing = new Adw.PreferencesGroup ();
            routing.title = "Routing";
            routing.description = "Enable either or both. Each runs independently after connect.";
            prefs.add (routing);

            system_proxy_row = new Adw.SwitchRow ();
            system_proxy_row.title = "System proxy";
            system_proxy_row.subtitle = "Set GNOME desktop proxy to the Psiphon local ports";
            routing.add (system_proxy_row);

            tun_row = new Adw.SwitchRow ();
            tun_row.title = "TUN routing";
            tun_row.subtitle = "Route all traffic through sing-box into the Psiphon SOCKS proxy";
            routing.add (tun_row);
            tun_row.notify["active"].connect (() => update_routing_rows ());

            sing_box_path_row = new Adw.EntryRow ();
            sing_box_path_row.title = "sing-box path";
            var sing_box_browse = new Gtk.Button.from_icon_name ("folder-open-symbolic");
            sing_box_browse.valign = Gtk.Align.CENTER;
            sing_box_browse.tooltip_text = "Browse for sing-box";
            sing_box_browse.clicked.connect (() => browse_sing_box_path.begin ());
            sing_box_path_row.add_suffix (sing_box_browse);
            routing.add (sing_box_path_row);

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

            refresh_button = new Gtk.Button.with_label ("Refresh");
            refresh_button.valign = Gtk.Align.CENTER;
            refresh_button.clicked.connect (() => refresh_server_list.begin ());

            refresh_spinner = new Gtk.Spinner ();
            refresh_spinner.valign = Gtk.Align.CENTER;
            refresh_spinner.width_request = 24;
            refresh_spinner.height_request = 24;

            refresh_busy_label = new Gtk.Label ("Downloading…");
            refresh_busy_label.valign = Gtk.Align.CENTER;
            refresh_busy_label.add_css_class ("accent");

            var refresh_busy_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            refresh_busy_box.valign = Gtk.Align.CENTER;
            refresh_busy_box.append (refresh_spinner);
            refresh_busy_box.append (refresh_busy_label);

            refresh_stack = new Gtk.Stack ();
            refresh_stack.valign = Gtk.Align.CENTER;
            refresh_stack.halign = Gtk.Align.END;
            refresh_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            refresh_stack.transition_duration = 150;
            refresh_stack.add_named (refresh_button, "idle");
            refresh_stack.add_named (refresh_busy_box, "busy");
            refresh_stack.visible_child_name = "idle";

            refresh_row = new Adw.ActionRow ();
            refresh_row.title = "Server list";
            refresh_row.subtitle = "Download the latest official Psiphon server list.";
            refresh_row.add_suffix (refresh_stack);
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
            beast_mode_row.active = options.enable_beast_mode;
            timeout_row.active = options.enable_timeout;
            system_proxy_row.active = options.enable_system_proxy;
            tun_row.active = options.enable_tun;
            sing_box_path_row.text = options.sing_box_path;
            update_routing_rows ();
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
            options.enable_beast_mode = beast_mode_row.active;
            options.enable_timeout = timeout_row.active;
            options.enable_system_proxy = system_proxy_row.active;
            options.enable_tun = tun_row.active;
            options.sing_box_path = sing_box_path_row.text.strip ();
            return options;
        }

        private void update_routing_rows () {
            sing_box_path_row.visible = tun_row.active;
        }

        private async void browse_sing_box_path () {
            if (parent_window == null) {
                return;
            }

            var dialog = new Gtk.FileDialog ();
            dialog.title = "Select sing-box";

            try {
                File file = yield dialog.open (parent_window, null);
                sing_box_path_row.text = file.get_path ();
            } catch (Error err) {
                if (err is IOError.CANCELLED) {
                    return;
                }
                toast_overlay.add_toast (new Adw.Toast (err.message));
            }
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

        private void set_refresh_busy (bool busy) {
            refresh_in_progress = busy;
            refresh_button.sensitive = !busy;
            refresh_row.activatable = !busy;

            if (busy) {
                refresh_stack.visible_child_name = "busy";
                refresh_row.subtitle = "Downloading the latest official Psiphon server list…";
                refresh_spinner.start ();
            } else {
                refresh_stack.visible_child_name = "idle";
                refresh_row.subtitle = "Download the latest official Psiphon server list.";
                refresh_spinner.stop ();
            }
        }

        private async void refresh_server_list () {
            if (refresh_in_progress) {
                return;
            }

            set_refresh_busy (true);
            var progress_toast = new Adw.Toast ("Downloading server list…");
            progress_toast.timeout = 0;
            toast_overlay.add_toast (progress_toast);

            try {
                string path = yield server_list_service.refresh_server_list ();
                progress_toast.dismiss ();
                var done_toast = new Adw.Toast ("Server list saved to %s".printf (path));
                done_toast.timeout = 5;
                toast_overlay.add_toast (done_toast);
            } catch (Error err) {
                progress_toast.dismiss ();
                var error_toast = new Adw.Toast (err.message);
                error_toast.timeout = 6;
                toast_overlay.add_toast (error_toast);
            } finally {
                set_refresh_busy (false);
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
