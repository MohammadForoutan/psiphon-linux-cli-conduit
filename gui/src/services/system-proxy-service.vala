namespace PsiphonCliGui {
    private struct ProxySnapshot {
        int mode;
        string http_host;
        int http_port;
        string https_host;
        int https_port;
        string socks_host;
        int socks_port;
        bool use_same_proxy;
        bool saved;
    }

    public class SystemProxyService : Object {
        private ProxySnapshot snapshot;
        private bool active = false;

        public bool schema_available {
            get {
                return SettingsSchemaSource.get_default ().lookup (
                    "org.gnome.system.proxy",
                    true
                ) != null;
            }
        }

        public bool is_active {
            get { return active; }
        }

        public void enable (string http_endpoint, string socks_endpoint) throws Error {
            if (!schema_available) {
                throw new IOError.FAILED (
                    "Desktop proxy settings (org.gnome.system.proxy) are not available on this system."
                );
            }

            if (active) {
                return;
            }

            save_snapshot ();

            string http_host;
            int http_port;
            string socks_host;
            int socks_port;
            parse_endpoint (http_endpoint, out http_host, out http_port);
            parse_endpoint (socks_endpoint, out socks_host, out socks_port);

            var proxy = new Settings ("org.gnome.system.proxy");
            proxy.set_enum ("mode", 1);

            var http = new Settings ("org.gnome.system.proxy.http");
            http.set_string ("host", http_host);
            http.set_int ("port", http_port);

            var https = new Settings ("org.gnome.system.proxy.https");
            https.set_string ("host", http_host);
            https.set_int ("port", http_port);

            var socks = new Settings ("org.gnome.system.proxy.socks");
            socks.set_string ("host", socks_host);
            socks.set_int ("port", socks_port);

            proxy.set_boolean ("use-same-proxy", true);
            active = true;
        }

        public void disable () {
            if (!active || !snapshot.saved) {
                active = false;
                return;
            }

            if (!schema_available) {
                active = false;
                return;
            }

            var proxy = new Settings ("org.gnome.system.proxy");
            proxy.set_enum ("mode", snapshot.mode);

            var http = new Settings ("org.gnome.system.proxy.http");
            http.set_string ("host", snapshot.http_host);
            http.set_int ("port", snapshot.http_port);

            var https = new Settings ("org.gnome.system.proxy.https");
            https.set_string ("host", snapshot.https_host);
            https.set_int ("port", snapshot.https_port);

            var socks = new Settings ("org.gnome.system.proxy.socks");
            socks.set_string ("host", snapshot.socks_host);
            socks.set_int ("port", snapshot.socks_port);

            proxy.set_boolean ("use-same-proxy", snapshot.use_same_proxy);
            snapshot.saved = false;
            active = false;
        }

        private void save_snapshot () {
            var proxy = new Settings ("org.gnome.system.proxy");
            snapshot.mode = proxy.get_enum ("mode");
            snapshot.use_same_proxy = proxy.get_boolean ("use-same-proxy");

            var http = new Settings ("org.gnome.system.proxy.http");
            snapshot.http_host = http.get_string ("host");
            snapshot.http_port = http.get_int ("port");

            var https = new Settings ("org.gnome.system.proxy.https");
            snapshot.https_host = https.get_string ("host");
            snapshot.https_port = https.get_int ("port");

            var socks = new Settings ("org.gnome.system.proxy.socks");
            snapshot.socks_host = socks.get_string ("host");
            snapshot.socks_port = socks.get_int ("port");
            snapshot.saved = true;
        }

        private void parse_endpoint (string endpoint, out string host, out int port) {
            host = "127.0.0.1";
            port = Constants.SOCKS_PROXY_PORT;

            string[] parts = endpoint.split (":", 2);
            if (parts.length == 2) {
                host = parts[0].strip ();
                port = int.parse (parts[1].strip ());
            }

            if (host == "0.0.0.0") {
                host = "127.0.0.1";
            }
        }
    }
}
