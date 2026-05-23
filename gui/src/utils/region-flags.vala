namespace PsiphonCliGui {
    public class RegionFlags {
        public static string flag_for_code (string code) {
            if (code == null || code.length != 2) {
                return "";
            }

            string upper = code.up ();
            unichar a = upper.get_char (0);
            unichar b = upper.get_char (1);

            if (a < 'A' || a > 'Z' || b < 'A' || b > 'Z') {
                return "";
            }

            unichar flag_a = 0x1F1E6 + (a - 'A');
            unichar flag_b = 0x1F1E6 + (b - 'A');
            var builder = new StringBuilder ();
            builder.append_unichar (flag_a);
            builder.append_unichar (flag_b);
            return builder.str;
        }
    }
}
