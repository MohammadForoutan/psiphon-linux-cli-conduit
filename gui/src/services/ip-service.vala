namespace PsiphonCliGui {
    public class IpService : Object {
        public signal void ip_fetched (string ip);

        public async void fetch_public_ip (string proxy_host, int port) {
            string command = "curl -s --max-time 10 -x http://%s:%d https://api.ipify.org".printf (
                proxy_host,
                port
            );

            try {
                string? stdout;
                string? stderr;
                int exit_status;
                Process.spawn_command_line_sync (
                    command,
                    out stdout,
                    out stderr,
                    out exit_status
                );

                if (exit_status == 0 && stdout != null) {
                    string ip = stdout.strip ();
                    if (ip.length > 0) {
                        ip_fetched (ip);
                    }
                }
            } catch (Error err) {
                warning ("Could not fetch public IP: %s", err.message);
            }
        }
    }
}
