namespace PsiphonCliGui {
    public class Region : Object {
        public string code { get; construct; }
        public string name { get; construct; }

        public Region (string code, string name) {
            Object (code: code, name: name);
        }

        public string flag () {
            return RegionFlags.flag_for_code (code);
        }

        public string display_name () {
            return "%s - %s".printf (code, name);
        }

        public string display_name_with_flag () {
            string flag = flag ();
            if (flag.length > 0) {
                return "%s %s - %s".printf (flag, code, name);
            }
            return display_name ();
        }

        public static Region[] all () {
            return {
                new Region ("US", "United States"),
                new Region ("DE", "Germany"),
                new Region ("NL", "Netherlands"),
                new Region ("CA", "Canada"),
                new Region ("GB", "United Kingdom"),
                new Region ("FR", "France"),
                new Region ("SG", "Singapore"),
                new Region ("JP", "Japan"),
                new Region ("AU", "Australia"),
                new Region ("IN", "India"),
                new Region ("BR", "Brazil"),
                new Region ("PL", "Poland"),
                new Region ("SE", "Sweden"),
                new Region ("CH", "Switzerland"),
                new Region ("ES", "Spain"),
                new Region ("IT", "Italy"),
                new Region ("RO", "Romania"),
                new Region ("CZ", "Czech Republic"),
                new Region ("AT", "Austria"),
                new Region ("BE", "Belgium"),
                new Region ("HK", "Hong Kong"),
                new Region ("KR", "South Korea"),
                new Region ("IE", "Ireland"),
                new Region ("PT", "Portugal"),
                new Region ("NO", "Norway"),
                new Region ("FI", "Finland"),
                new Region ("UA", "Ukraine"),
                new Region ("TR", "Turkey"),
                new Region ("MX", "Mexico")
            };
        }
    }
}
