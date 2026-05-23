namespace PsiphonCliGui {
    public class TunnelOptions : Object {
        public ProtocolMode protocol { get; set; default = ProtocolMode.AUTO; }
        public string region { get; set; default = ""; }
        public string upstream_proxy_url { get; set; default = ""; }
        public bool enable_timeout { get; set; default = false; }
        public bool enable_lan { get; set; default = false; }
        public string core_path { get; set; default = ""; }
        public string config_dir { get; set; default = ""; }
    }
}
