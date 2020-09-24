int main (string[] args) {
    var app = new Gtk4Demo.ShaderToyApplication();
    return app.run (args);
}

public class Gtk4Demo.ShaderToyApplication : Gtk.Application {
    public ShaderToyApplication () {
        Object (application_id: "github.aeldemery.gtk4_shadertoy",
                flags : GLib.ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var win = active_window;
        if (win == null) {
            win = new Gtk4Demo.MainWindow (this);
        }
        win.present();
    }
}