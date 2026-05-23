namespace PsiphonCliGui {
    public class TunnelStats : Object {
        public string protocol { get; set; default = "auto"; }
        public string status { get; set; default = "disconnected"; }
        public string http_proxy { get; set; default = "127.0.0.1:8081"; }
        public string socks_proxy { get; set; default = "127.0.0.1:1081"; }
        public int tunnel_count { get; set; default = 0; }
        public string client_region { get; set; default = "-"; }
        public string egress_region { get; set; default = "-"; }
        public int64 downstream_bps { get; set; default = 0; }
        public int64 upstream_bps { get; set; default = 0; }
        public int64 total_down_bytes { get; set; default = 0; }
        public int64 total_up_bytes { get; set; default = 0; }
        public string diagnostic_id { get; set; default = "-"; }
        public string tunnel_protocol { get; set; default = "-"; }
        public int available_regions { get; set; default = 0; }
        public int64 started_at_ms { get; set; default = 0; }
        public int64 uptime_ms { get; set; default = 0; }
        public int64 connected_at_ms { get; set; default = 0; }
        public int64 connect_duration_ms { get; set; default = 0; }
        public string public_ip { get; set; default = "-"; }

        public TunnelStats copy () {
            var stats = new TunnelStats ();
            stats.protocol = protocol;
            stats.status = status;
            stats.http_proxy = http_proxy;
            stats.socks_proxy = socks_proxy;
            stats.tunnel_count = tunnel_count;
            stats.client_region = client_region;
            stats.egress_region = egress_region;
            stats.downstream_bps = downstream_bps;
            stats.upstream_bps = upstream_bps;
            stats.total_down_bytes = total_down_bytes;
            stats.total_up_bytes = total_up_bytes;
            stats.diagnostic_id = diagnostic_id;
            stats.tunnel_protocol = tunnel_protocol;
            stats.available_regions = available_regions;
            stats.started_at_ms = started_at_ms;
            stats.uptime_ms = uptime_ms;
            stats.connected_at_ms = connected_at_ms;
            stats.connect_duration_ms = connect_duration_ms;
            stats.public_ip = public_ip;
            return stats;
        }
    }
}
