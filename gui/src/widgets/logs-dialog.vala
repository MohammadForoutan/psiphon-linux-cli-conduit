namespace PsiphonCliGui {
    public class LogsWindow : Adw.Window {
        private Gtk.TextView text_view;
        private Gtk.TextBuffer text_buffer;

        public LogsWindow (Gtk.Window parent) {
            Object (
                transient_for: parent,
                title: "Tunnel logs",
                hide_on_close: true
            );

            set_default_size (680, 560);

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            set_content (root);

            var header = new Adw.HeaderBar ();
            header.show_title = true;
            root.append (header);

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.vexpand = true;
            scrolled.margin_top = 12;
            scrolled.margin_bottom = 12;
            scrolled.margin_start = 18;
            scrolled.margin_end = 18;
            root.append (scrolled);

            var clamp = new Adw.Clamp ();
            clamp.maximum_size = 640;
            clamp.tightening_threshold = 480;
            scrolled.set_child (clamp);

            text_view = new Gtk.TextView ();
            text_view.editable = false;
            text_view.monospace = true;
            text_view.wrap_mode = Gtk.WrapMode.NONE;
            text_view.left_margin = 8;
            text_view.right_margin = 8;
            text_view.top_margin = 8;
            text_view.bottom_margin = 8;
            text_buffer = text_view.buffer;
            clamp.set_child (text_view);
        }

        public void set_text (string text) {
            text_buffer.text = text;
            scroll_to_end ();
        }

        public void append_line (string line) {
            if (line.length == 0) {
                return;
            }

            Gtk.TextIter end;
            text_buffer.get_end_iter (out end);
            text_buffer.insert (ref end, line + "\n", -1);
            scroll_to_end ();
        }

        private void scroll_to_end () {
            Gtk.TextIter end;
            text_buffer.get_end_iter (out end);
            text_view.scroll_to_iter (end, 0, false, 0, 0);
        }
    }
}
