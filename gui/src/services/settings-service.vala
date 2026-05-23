namespace PsiphonCliGui {
    public class SettingsService : Object {
        private Settings settings;

        public SettingsService () {
            settings = new Settings (Constants.SETTINGS_SCHEMA_ID);
        }

        public TunnelOptions load_options () {
            var options = new TunnelOptions ();
            options.protocol = ProtocolMode.from_index (settings.get_int ("protocol"));
            options.region = settings.get_string ("region");
            options.upstream_proxy_url = settings.get_string ("upstream-proxy");
            options.core_path = settings.get_string ("core-path");
            options.config_dir = settings.get_string ("config-dir");
            options.enable_lan = settings.get_boolean ("enable-lan");
            options.enable_timeout = settings.get_boolean ("enable-timeout");
            return options;
        }

        public void save_options (TunnelOptions options) {
            settings.set_int ("protocol", (int) options.protocol);
            settings.set_string ("region", options.region);
            settings.set_string ("upstream-proxy", options.upstream_proxy_url);
            settings.set_string ("core-path", options.core_path);
            settings.set_string ("config-dir", options.config_dir);
            settings.set_boolean ("enable-lan", options.enable_lan);
            settings.set_boolean ("enable-timeout", options.enable_timeout);
        }
    }
}
