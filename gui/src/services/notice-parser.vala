namespace PsiphonCliGui {
    public class NoticeParser : Object {
        private int64 last_bytes_time_ms = 0;

        public bool apply_line (string line, TunnelStats stats, string proxy_host) {
            string trimmed = line.strip ();
            if (trimmed.length == 0) {
                return false;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data (trimmed, trimmed.length);
                Json.Object root = parser.get_root ().get_object ();
                string notice_type = get_string (root, "noticeType", "");
                Json.Object? data = null;

                if (root.has_member ("data") && root.get_member ("data").get_node_type () == Json.NodeType.OBJECT) {
                    data = root.get_object_member ("data");
                }

                switch (notice_type) {
                    case "RemoteServerListDownloadFailed":
                    case "RemoteServerListFetchFailed":
                        warning ("Remote server list download failed; psiphon-tunnel-core will rely on any cached local list if available.");
                        return false;

                    case "ListeningSocksProxyPort":
                        if (data != null) {
                            stats.socks_proxy = "%s:%lld".printf (proxy_host, get_int (data, "port", Constants.SOCKS_PROXY_PORT));
                            return true;
                        }
                        break;

                    case "ListeningHttpProxyPort":
                        if (data != null) {
                            stats.http_proxy = "%s:%lld".printf (proxy_host, get_int (data, "port", Constants.HTTP_PROXY_PORT));
                            return true;
                        }
                        break;

                    case "Tunnels":
                        if (data != null) {
                            stats.tunnel_count = (int) get_int (data, "count", 0);
                            if (stats.tunnel_count > 0) {
                                stats.status = "connected";
                            } else if (stats.status == "connected") {
                                stats.status = "disconnecting";
                            } else {
                                stats.status = "connecting";
                            }
                            return true;
                        }
                        break;

                    case "ClientRegion":
                        if (data != null) {
                            stats.client_region = get_string (data, "region", "-");
                            return true;
                        }
                        break;

                    case "ConnectedServerRegion":
                        if (data != null) {
                            stats.egress_region = get_string (data, "serverRegion", "-");
                            return true;
                        }
                        break;

                    case "TrafficRateLimits":
                        if (data != null) {
                            stats.downstream_bps = get_int (data, "downstreamBytesPerSecond", 0);
                            stats.upstream_bps = get_int (data, "upstreamBytesPerSecond", 0);
                            return true;
                        }
                        break;

                    case "BytesTransferred":
                        if (data != null) {
                            int64 received = get_int (data, "received", 0);
                            int64 sent = get_int (data, "sent", 0);
                            stats.total_down_bytes += received;
                            stats.total_up_bytes += sent;

                            int64 now = now_ms ();
                            if (last_bytes_time_ms > 0 && (received > 0 || sent > 0)) {
                                double elapsed_sec = (now - last_bytes_time_ms) / 1000.0;
                                if (elapsed_sec > 0) {
                                    stats.downstream_bps = (int64) ((received / elapsed_sec) + 0.5);
                                    stats.upstream_bps = (int64) ((sent / elapsed_sec) + 0.5);
                                }
                            }
                            last_bytes_time_ms = now;
                            return true;
                        }
                        break;

                    case "TotalBytesTransferred":
                        if (data != null) {
                            if (data.has_member ("received")) {
                                stats.total_down_bytes = get_int (data, "received", stats.total_down_bytes);
                            }
                            if (data.has_member ("sent")) {
                                stats.total_up_bytes = get_int (data, "sent", stats.total_up_bytes);
                            }
                            return true;
                        }
                        break;

                    case "ActiveTunnel":
                        if (data != null) {
                            stats.tunnel_protocol = get_string (data, "protocol", "-");
                            return true;
                        }
                        break;

                    case "AvailableEgressRegions":
                        if (data != null && data.has_member ("regions")) {
                            Json.Array regions = data.get_array_member ("regions");
                            stats.available_regions = (int) regions.get_length ();
                            return true;
                        }
                        break;

                    case "ServerTimestamp":
                        if (data != null) {
                            stats.diagnostic_id = get_string (data, "diagnosticID", "-");
                            return true;
                        }
                        break;

                    case "Exiting":
                        stats.status = "exiting";
                        return true;
                }
            } catch (Error err) {
                return false;
            }

            return false;
        }

        private string get_string (Json.Object obj, string name, string fallback) {
            if (!obj.has_member (name)) {
                return fallback;
            }
            Json.Node node = obj.get_member (name);
            if (node.get_value_type () == typeof (string)) {
                return obj.get_string_member (name);
            }
            return fallback;
        }

        private int64 get_int (Json.Object obj, string name, int64 fallback) {
            if (!obj.has_member (name)) {
                return fallback;
            }
            Json.Node node = obj.get_member (name);
            if (node.get_value_type () == typeof (int64) || node.get_value_type () == typeof (int)) {
                return obj.get_int_member (name);
            }
            return fallback;
        }

        private int64 now_ms () {
            return GLib.get_real_time () / 1000;
        }
    }
}
