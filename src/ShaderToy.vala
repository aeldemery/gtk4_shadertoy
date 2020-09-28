public class Gtk4Demo.ShaderToy : Gtk.GLArea {
    const string default_image_shader =
"""
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    if (distance(iMouse.xy, fragCoord.xy) <= 10.0) {
        col = vec3(0.0);
    }

    // Output to screen
    fragColor = vec4(col,1.0);
}
""";

    const string shadertoy_vertex_shader =
"""
#version 150 core

uniform vec3 iResolution;

in vec2 position;
out vec2 fragCoord;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    // Convert from OpenGL coordinate system (with origin in center
    // of screen) to Shadertoy/texture coordinate system (with origin
    // in lower left corner)\n"
    fragCoord = (gl_Position.xy + vec2(1.0)) / vec2(2.0) * iResolution.xy;
}
""";

    const string fragment_prefix =
"""
#version 150 core

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec4      iDate;                 // (year, month, day, time in seconds)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

in vec2 fragCoord;
out vec4 fragColor;
""";

    // Fragment shader suffix
    const string fragment_suffix =
"""
void main() {
    mainImage(fragColor, fragCoord);
}
""";


    private string _image_shader;
    public string image_shader {
        get {
            return _image_shader;
        }
        set {
            _image_shader = null;
            _image_shader = value;
            /* Don't override error we didn't set it ourselves */
            if (this.error_set) {
                this.set_error (null);
                this.error_set = false;
            }
            this.image_shader_dirty = true;
        }
    }

    bool image_shader_dirty;

    bool error_set;

    /* Vertex buffers */
    GL.GLuint vao;
    GL.GLuint buffer;

    /* Active program */
    GL.GLuint program;

    /* Location of uniforms for program */
    GL.GLint resolution_location;
    GL.GLint time_location;
    GL.GLint timedelta_location;
    GL.GLint frame_location;
    GL.GLint mouse_location;

    /* Current uniform values */
    float resolution[3];
    float time;
    float timedelta;
    float mouse[4];
    int frame;

    /* Animation data */
    int64 first_frame_time;
    int64 first_frame;
    uint tick;

    public ShaderToy (string ? file_name = null) {
        if (file_name == null) {
            this.image_shader = default_image_shader;
        } else {
            try {
                var shader_resource = GLib.resources_lookup_data (file_name,
                                                                  GLib.ResourceLookupFlags.NONE);
                var shader = (string) shader_resource.get_data ();
                this.image_shader = shader;
            } catch (Error error) {
                critical ("Couldn't load resource");
            }
        }

        this.tick = this.add_tick_callback (do_tick);

        var drag = new Gtk.GestureDrag ();
        this.add_controller (drag);
        drag.drag_begin.connect (drag_begin_cb);
        drag.drag_update.connect (drag_update_cb);
        drag.drag_end.connect (drag_end_cb);
    }

    void drag_begin_cb (Gtk.GestureDrag drag, double x, double y) {
        int height = this.get_height ();
        int scale = this.get_scale_factor ();

        this.mouse[0] = (float) (x * scale);
        this.mouse[1] = (float) ((height - y) * scale);
        this.mouse[2] = this.mouse[0];
        this.mouse[3] = this.mouse[1];
    }

    void drag_update_cb (Gtk.GestureDrag drag, double dx, double dy) {
        int width = this.get_width ();
        int height = this.get_height ();
        int scale = this.get_scale_factor ();
        double x, y;

        drag.get_start_point (out x, out y);
        x += dx;
        y += dy;

        if (x >= 0 && x < width &&
            y >= 0 && y < height) {
            this.mouse[0] = (float) (x * scale);
            this.mouse[1] = (float) ((height - y) * scale);
        }
    }

    void drag_end_cb (Gtk.GestureDrag drag, double dx, double dy) {
        this.mouse[2] = -this.mouse[2];
        this.mouse[3] = -this.mouse[3];
    }

    protected override bool render (Gdk.GLContext gl_context) {
        if (this.get_error () != null)
            return false;

        if (this.image_shader_dirty)
            this.realize_shader ();

        /* Clear the viewport */
        GL.glClearColor (0.0f, 0.0f, 0.0f, 1.0f);
        GL.glClear (GL.GL_COLOR_BUFFER_BIT);

        GL.glUseProgram (this.program);

        /* Update uniforms */
        if (this.resolution_location != -1)
            GL.glUniform3fv (this.resolution_location, 1, this.resolution);
        if (this.time_location != -1)
            GL.glUniform1f (this.time_location, this.time);
        if (this.timedelta_location != -1)
            GL.glUniform1f (this.timedelta_location, this.timedelta);
        if (this.frame_location != -1)
            GL.glUniform1i (this.frame_location, this.frame);
        if (this.mouse_location != -1)
            GL.glUniform4fv (this.mouse_location, 1, this.mouse);

        /* Use the vertices in our buffer */
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, this.buffer);
        GL.glEnableVertexAttribArray (0);
        GL.glVertexAttribPointer (0, 4, GL.GL_FLOAT, (GL.GLboolean)GL.GL_FALSE, 0, null);

        GL.glDrawArrays (GL.GL_TRIANGLES, 0, 6);

        /* We finished using the buffers and program */
        GL.glDisableVertexAttribArray (0);
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, 0);
        GL.glUseProgram (0);

        /* Flush the contents of the pipeline */
        GL.glFlush ();

        return true;
    }

    protected override void resize (int width, int height) {
        this.resolution[0] = width;
        this.resolution[1] = height;
        this.resolution[2] = 1.0f; /* screen aspect ratio */

        /* Set the viewport */
        GL.glViewport (0, 0, (GL.GLint)width, (GL.GLint)height);
    }

    protected override void realize () {
        base.realize ();

        /* Draw two triangles across whole screen */
        const GL.GLfloat vertex_data[] = {
            -1.0f, -1.0f, 0.0f, 1.0f,
            -1.0f, 1.0f, 0.0f, 1.0f,
            1.0f, 1.0f, 0.0f, 1.0f,

            -1.0f, -1.0f, 0.0f, 1.0f,
            1.0f, 1.0f, 0.0f, 1.0f,
            1.0f, -1.0f, 0.0f, 1.0f,
        };

        this.make_current ();
        if (this.get_error () != null)
            return;

        GL.GLuint[] local_vao = {this.vao};
        GL.glGenVertexArrays (1, local_vao);
        this.vao = local_vao[0];
        GL.glBindVertexArray (this.vao);

        GL.GLuint[] local_buffer = {this.buffer};
        GL.glGenBuffers (1, local_buffer);
        this.buffer = local_buffer[0];
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, this.buffer);
        GL.glBufferData (
            GL.GL_ARRAY_BUFFER,
            sizeof (GL.GLfloat) * vertex_data.length,
            (GL.GLvoid[])vertex_data,
            GL.GL_STATIC_DRAW
        );
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, 0);

        this.realize_shader ();
    }

    void realize_shader () {
        string fragment_shader;
        fragment_shader = fragment_prefix + this.image_shader + fragment_suffix;

        try {
            init_shaders (shadertoy_vertex_shader, fragment_shader);
        } catch (ShaderError error) {
            critical (error.message);
            this.error_set = true;
            this.set_error (error);
        }

        /* Start new shader at time zero */
        this.first_frame_time = 0;
        this.first_frame = 0;

        this.image_shader_dirty = false;
    }

    void init_shaders (string vertex_source, string fragment_source) throws ShaderError {
        GL.GLuint init_vertex = 0, init_fragment = 0;
        GL.GLuint init_program = 0;
        int[] status = {0};

        try {
            create_shader (out init_vertex, GL.GL_VERTEX_SHADER, vertex_source);
            if (init_vertex == 0) {
                critical ("Couldn't create vertex shader.\n");
            }

            create_shader (out init_fragment, GL.GL_FRAGMENT_SHADER, fragment_source);
            if (init_fragment == 0) {
                critical ("Couldn't create fragment shader.\n");
                GL.glDeleteShader (init_vertex);
            }
        } catch (ShaderError error) {
            critical (error.message);
            this.error_set = true;
            this.set_error (error);
            return;
        }

        init_program = GL.glCreateProgram ();
        GL.glAttachShader (init_program, init_vertex);
        GL.glAttachShader (init_program, init_fragment);

        GL.glLinkProgram (init_program);

        GL.glGetProgramiv (init_program, GL.GL_LINK_STATUS, status);
        if (status[0] == GL.GL_FALSE) {
            GL.GLint[] log_len = {0};

            GL.glGetProgramiv (init_program, GL.GL_INFO_LOG_LENGTH, log_len);

            GL.GLubyte[] buffer = new GL.GLubyte[log_len[0]];

            GL.glGetProgramInfoLog (init_program, log_len[0], log_len, buffer);

            GL.glDeleteProgram (init_program);
            GL.glDeleteShader (init_vertex);
            GL.glDeleteShader (init_fragment);
            throw new ShaderError.LINKING_ERROR ("Linking Failed: %s\n", (string) buffer);
        }

        if (this.program != 0)
            GL.glDeleteProgram (this.program);

        this.program = init_program;
        this.resolution_location = GL.glGetUniformLocation (init_program, "iResolution");
        this.time_location = GL.glGetUniformLocation (init_program, "iTime");
        this.timedelta_location = GL.glGetUniformLocation (init_program, "iTimeDelta");
        this.frame_location = GL.glGetUniformLocation (init_program, "iFrame");
        this.mouse_location = GL.glGetUniformLocation (init_program, "iMouse");

        GL.glDetachShader (init_program, init_vertex);
        GL.glDetachShader (init_program, init_fragment);

        GL.glDeleteShader (init_vertex);
        GL.glDeleteShader (init_fragment);
    }

    void create_shader (out GL.GLuint shader, int type, string src) throws ShaderError {
        shader = 0;
        int[] status = {0};
        string[] src_array = { src, null };

        shader = GL.glCreateShader (type);

        GL.glShaderSource (shader, 1, src_array, null);
        GL.glCompileShader (shader);

        GL.glGetShaderiv (shader, GL.GL_COMPILE_STATUS, status);
        if (status[0] == GL.GL_FALSE) {
            int[] log_len = {0};
            GL.glGetShaderiv (shader, GL.GL_INFO_LOG_LENGTH, log_len);
            GL.GLubyte[] buffer = new GL.GLubyte[log_len[0]];
            GL.glGetShaderInfoLog (shader, log_len[0], log_len, buffer);
            GL.glDeleteShader (shader);

            throw new ShaderError.COMPILATION_ERROR ("Compile failure in %s shader:\n%s",
                                                     type == GL.GL_VERTEX_SHADER ? "vertex" : "fragment",
                                                     (string) buffer);
        }
    }

    protected override void unrealize () {
        this.make_current ();
        GL.GLuint[] local_vao = {this.vao};
        GL.GLuint[] local_buffer = {this.buffer};
        if (this.get_error () == null) {
            if (this.buffer != 0)
                GL.glDeleteBuffers (1, local_buffer);

            if (this.vao != 0)
                GL.glDeleteVertexArrays (1, local_vao);

            if (this.program != 0)
                GL.glDeleteProgram (this.program);
        }

        base.unrealize ();
    }

    protected bool do_tick (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
        int64 tick_frame_time;
        int64 tick_frame;
        float tick_previous_time;

        tick_frame = frame_clock.get_frame_counter ();
        tick_frame_time = frame_clock.get_frame_time ();

        if (this.first_frame_time == 0) {
            this.first_frame_time = tick_frame_time;
            this.first_frame = tick_frame;
            tick_previous_time = 0;
        } else {
            tick_previous_time = this.time;
        }

        this.time = (tick_frame_time - this.first_frame_time) / 1000000.0f;
        this.frame = (int) (tick_frame - this.first_frame);
        this.timedelta = this.time - tick_previous_time;

        this.queue_draw ();

        return Source.CONTINUE;
    }

    ~ShaderToy () {
        this.remove_tick_callback (this.tick);
    }
}

public errordomain Gtk4Demo.ShaderError {
    PARSING_ERROR,
    COMPILATION_ERROR,
    LINKING_ERROR
}