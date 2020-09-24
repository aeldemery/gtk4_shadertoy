public class Gtk4Demo.MainWindow : Gtk.ApplicationWindow {
    public MainWindow (Gtk.Application app) {
        Object (application: app);

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

        var shadertoy = new ShaderToy ("/github/aeldemery/gtk4_shadertoy/alienplanet.glsl");
        //var shadertoy = new ShaderToy (null);
        aspect_frame.set_child (shadertoy);

        var sw = new Gtk.ScrolledWindow ();
        sw.min_content_height = 250;
        sw.has_frame = true;
        sw.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        sw.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        sw.hexpand = true;

        box.append (sw);

        var textview = new Gtk.TextView ();
        textview.monospace = true;
        textview.bottom_margin = 20;
        textview.top_margin = 20;
        textview.left_margin = 20;
        textview.right_margin = 20;

        sw.set_child (textview);

        textview.buffer.text = shadertoy.image_shader;

        var centerbox = new Gtk.CenterBox ();
        box.append (centerbox);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        centerbox.set_start_widget (hbox);

        var refreash_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic");
        refreash_button.tooltip_text = "Restart the Demo";
        refreash_button.valign = Gtk.Align.CENTER;

        hbox.append (refreash_button);

        var clear_button = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic");
        clear_button.tooltip_text = "Clear the text view";
        clear_button.valign = Gtk.Align.CENTER;
        
        hbox.append (clear_button);
    }
}