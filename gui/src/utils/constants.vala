namespace PsiphonCliGui.Constants {
    public const string APPLICATION_ID = "io.github.MohammadForoutan.PsiphonCliGui";
    public const string SETTINGS_SCHEMA_ID = "io.github.MohammadForoutan.PsiphonCliGui";

    public const string PSIPHON_BIN = "psiphon-tunnel-core-x86_64";
    public const string CONFIG_FILE = "psiphon.config";
    public const string STATS_FILE = "stats.json";
    public const string PID_FILE = "psiphon.pid";
    public const string LOG_FILE = "psiphon.log";
    public const string SERVER_LIST_FILE = "remote_server_list";

    public const int HTTP_PROXY_PORT = 8081;
    public const int SOCKS_PROXY_PORT = 1081;
    public const uint STATS_UPDATE_MS = 2000;

    public string[] direct_protocols () {
        return {
            "SSH",
            "OSSH",
            "TLS-OSSH",
            "UNFRONTED-MEEK-OSSH",
            "UNFRONTED-MEEK-HTTPS-OSSH",
            "UNFRONTED-MEEK-SESSION-TICKET-OSSH",
            "FRONTED-MEEK-OSSH",
            "FRONTED-MEEK-HTTP-OSSH",
            "QUIC-OSSH",
            "FRONTED-MEEK-QUIC-OSSH",
            "CONJURE-OSSH",
            "SHADOWSOCKS-OSSH"
        };
    }

    public string[] conduit_protocols () {
        return {
            "INPROXY-WEBRTC-SSH",
            "INPROXY-WEBRTC-OSSH",
            "INPROXY-WEBRTC-TLS-OSSH",
            "INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH",
            "INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
            "INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
            "INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
            "INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
            "INPROXY-WEBRTC-QUIC-OSSH",
            "INPROXY-WEBRTC-FRONTED-MEEK-QUIC-OSSH",
            "INPROXY-WEBRTC-SHADOWSOCKS-OSSH"
        };
    }

    public string default_config_dir () {
        return Path.build_filename (Environment.get_home_dir (), ".config", "psiphon-cli");
    }
}
