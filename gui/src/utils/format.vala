namespace PsiphonCliGui.Format {
    public string bytes_per_sec (int64 bps) {
        if (bps >= 1024 * 1024) {
            return "%.2f MB/s".printf ((double) bps / 1024.0 / 1024.0);
        }
        if (bps >= 1024) {
            return "%.2f KB/s".printf ((double) bps / 1024.0);
        }
        return "%lld B/s".printf (bps);
    }

    public string bytes (int64 value) {
        if (value >= 1024LL * 1024LL * 1024LL) {
            return "%.2f GB".printf ((double) value / 1024.0 / 1024.0 / 1024.0);
        }
        if (value >= 1024 * 1024) {
            return "%.2f MB".printf ((double) value / 1024.0 / 1024.0);
        }
        if (value >= 1024) {
            return "%.2f KB".printf ((double) value / 1024.0);
        }
        return "%lld B".printf (value);
    }

    public string uptime (int64 ms) {
        int64 seconds = ms / 1000;
        int64 minutes = seconds / 60;
        int64 hours = minutes / 60;

        if (hours > 0) {
            return "%lldh %lldm".printf (hours, minutes % 60);
        }
        if (minutes > 0) {
            return "%lldm %llds".printf (minutes, seconds % 60);
        }
        return "%llds".printf (seconds);
    }
}
