namespace PsiphonCliGui {
    public class StatsService : Object {
        private ConfigService config;

        public StatsService (ConfigService config) {
            this.config = config;
        }

        public void write_stats (TunnelStats stats) {
            try {
                var builder = new Json.Builder ();
                builder.begin_object ();
                builder.set_member_name ("protocol");
                builder.add_string_value (stats.protocol);
                builder.set_member_name ("status");
                builder.add_string_value (stats.status);
                builder.set_member_name ("httpProxy");
                builder.add_string_value (stats.http_proxy);
                builder.set_member_name ("socksProxy");
                builder.add_string_value (stats.socks_proxy);
                builder.set_member_name ("tunnelCount");
                builder.add_int_value (stats.tunnel_count);
                builder.set_member_name ("clientRegion");
                builder.add_string_value (stats.client_region);
                builder.set_member_name ("egressRegion");
                builder.add_string_value (stats.egress_region);
                builder.set_member_name ("downstreamBps");
                builder.add_int_value (stats.downstream_bps);
                builder.set_member_name ("upstreamBps");
                builder.add_int_value (stats.upstream_bps);
                builder.set_member_name ("totalDownBytes");
                builder.add_int_value (stats.total_down_bytes);
                builder.set_member_name ("totalUpBytes");
                builder.add_int_value (stats.total_up_bytes);
                builder.set_member_name ("diagnosticID");
                builder.add_string_value (stats.diagnostic_id);
                builder.set_member_name ("tunnelProtocol");
                builder.add_string_value (stats.tunnel_protocol);
                builder.set_member_name ("availableRegions");
                builder.add_int_value (stats.available_regions);
                builder.set_member_name ("startedAt");
                builder.add_int_value (stats.started_at_ms);
                builder.set_member_name ("uptimeMs");
                builder.add_int_value (stats.uptime_ms);
                builder.end_object ();

                var generator = new Json.Generator ();
                generator.set_root (builder.get_root ());
                string output = generator.to_data (null);
                FileUtils.set_contents (config.stats_path (), output);
            } catch (Error err) {
                warning ("Could not write stats file: %s", err.message);
            }
        }

        public void delete_stats () {
            if (FileUtils.test (config.stats_path (), FileTest.EXISTS)) {
                FileUtils.remove (config.stats_path ());
            }
        }
    }
}
