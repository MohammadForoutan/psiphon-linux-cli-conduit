namespace PsiphonCliGui {
    public enum ProtocolMode {
        AUTO,
        CONDUIT,
        DIRECT;

        public string label () {
            switch (this) {
                case CONDUIT:
                    return "Conduit";
                case DIRECT:
                    return "Direct";
                case AUTO:
                default:
                    return "Auto";
            }
        }

        public string config_value () {
            switch (this) {
                case CONDUIT:
                    return "conduit";
                case DIRECT:
                    return "direct";
                case AUTO:
                default:
                    return "auto";
            }
        }

        public static ProtocolMode from_index (uint index) {
            switch (index) {
                case 1:
                    return CONDUIT;
                case 2:
                    return DIRECT;
                case 0:
                default:
                    return AUTO;
            }
        }
    }
}
