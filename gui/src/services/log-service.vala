namespace PsiphonCliGui {
    public class LogService : Object {
        public signal void line_appended (string line);

        private ConfigService config;
        private FileOutputStream? log_stream = null;
        private StringBuilder buffer = new StringBuilder ();

        public LogService (ConfigService config) {
            this.config = config;
        }

        public void start_session () {
            close_session ();
            buffer = new StringBuilder ();
            try {
                if (FileUtils.test (config.log_path (), FileTest.EXISTS)) {
                    FileUtils.remove (config.log_path ());
                }
                log_stream = File.new_for_path (config.log_path ()).create (FileCreateFlags.NONE, null);
            } catch (Error err) {
                warning ("Could not open log file: %s", err.message);
                log_stream = null;
            }
        }

        public void append_line (string line) {
            if (line.length == 0) {
                return;
            }

            string pretty = pretty_line (line);
            buffer.append (pretty);
            buffer.append_c ('\n');
            line_appended (pretty);

            if (log_stream != null) {
                try {
                    var bytes = pretty.data;
                    log_stream.write (bytes);
                    log_stream.write ("\n".data);
                } catch (Error err) {
                    warning ("Could not write log line: %s", err.message);
                }
            }
        }

        public string get_text () {
            return buffer.str;
        }

        public void close_session () {
            if (log_stream != null) {
                try {
                    log_stream.close (null);
                } catch (Error err) {
                    warning ("Could not close log file: %s", err.message);
                }
                log_stream = null;
            }
        }

        private string pretty_line (string line) {
            string trimmed = line.strip ();
            if (trimmed.length == 0) {
                return "";
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data (trimmed, trimmed.length);
                var generator = new Json.Generator ();
                generator.pretty = true;
                generator.set_root (parser.get_root ());
                return generator.to_data (null);
            } catch (Error err) {
                return trimmed;
            }
        }
    }
}
