public class Gtk4Demo.MainWindow : Gtk.ApplicationWindow {
    string[] resource_paths;
    Gtk.TextView textview;
    ShaderToy shadertoy;
    ShaderToy preview_toy;
    Gtk.Button toy_button;
    Gtk.Button clear_button;
    Gtk.Button refresh_button;
    Gtk.Box toys_box;
    string current_shader_text;

    public MainWindow (Gtk.Application app) {
        Object (application: app);

        resource_paths = {
            "/github/aeldemery/gtk4_shadertoy/alienplanet.glsl",
            "/github/aeldemery/gtk4_shadertoy/mandelbrot.glsl",
            // "/github/aeldemery/gtk4_shadertoy/neon.glsl",
            "/github/aeldemery/gtk4_shadertoy/cogs.glsl",
            "/github/aeldemery/gtk4_shadertoy/glowingstars.glsl",
            "/github/aeldemery/gtk4_shadertoy/happyjumping.glsl",
            "/github/aeldemery/gtk4_shadertoy/proteanclouds.glsl"
        };

        title = "Shadertoy :)";
        default_width = 690;
        default_height = 740;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.margin_bottom = 12;
        box.margin_end = 12;
        box.margin_start = 12;
        box.margin_top = 12;

        set_child (box);

        var aspect_frame = new Gtk.AspectFrame (0.5f, 0.5f, 1.77777f, false);
        aspect_frame.hexpand = true;
        aspect_frame.vexpand = true;

        box.append (aspect_frame);

        shadertoy = new ShaderToy (resource_paths[0]);
        // var shadertoy = new ShaderToy (null);
        aspect_frame.set_child (shadertoy);

        var sw = new Gtk.ScrolledWindow ();
        sw.min_content_height = 250;
        sw.has_frame = true;
        sw.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        sw.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        sw.hexpand = true;

        box.append (sw);

        textview = new Gtk.TextView ();
        textview.monospace = true;
        textview.bottom_margin = 20;
        textview.top_margin = 20;
        textview.left_margin = 20;
        textview.right_margin = 20;

        sw.set_child (textview);

        textview.buffer.text = shadertoy.image_shader;
        textview.buffer.changed.connect (buffer_changed_cb);

        var centerbox = new Gtk.CenterBox ();
        box.append (centerbox);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        centerbox.set_start_widget (hbox);

        refresh_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic");
        refresh_button.tooltip_text = "Restart the Demo";
        refresh_button.valign = Gtk.Align.CENTER;
        refresh_button.clicked.connect (refresh_clicked_cb);

        hbox.append (refresh_button);

        clear_button = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic");
        clear_button.tooltip_text = "Clear the text view";
        clear_button.valign = Gtk.Align.CENTER;
        clear_button.clicked.connect (clear_clicked_cb);

        hbox.append (clear_button);

        toys_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        centerbox.set_end_widget (toys_box);

        foreach (var path in resource_paths) {
            toy_button = new Gtk.Button ();
            preview_toy = new ShaderToy (path);
            preview_toy.set_size_request (64, 36);
            toy_button.set_child (preview_toy);
            toys_box.append (toy_button);
            toy_button.clicked.connect (toy_button_clicked_cb);
        }
    }

    void buffer_changed_cb (Gtk.TextBuffer buffer) {
        current_shader_text = buffer.text;
        shadertoy.image_shader = current_shader_text;
    }

    void toy_button_clicked_cb (Gtk.Button button) {
        current_shader_text = ((ShaderToy) (button.child)).image_shader;
        textview.buffer.text = current_shader_text;
        shadertoy.image_shader = current_shader_text;
    }

    void refresh_clicked_cb (Gtk.Button button) {
        shadertoy.image_shader = current_shader_text;
    }

    void clear_clicked_cb (Gtk.Button button) {
        textview.buffer.text = "";
    }
}