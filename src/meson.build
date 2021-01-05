add_project_arguments([
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    #'--pkg', 'gl',
    '--pkg', 'epoxy',
    '--save-temps',
    ],
    language: 'vala'
)

shadertoy_sources = files (
    'Main.vala',
    'MainWindow.vala',
    'ShaderToy.vala',
)

shadertoy_sources += shadertoy_resources

shadertoy_dependencies = [
    dependency ('glib-2.0'),
    dependency ('gtk4', version: '>= 4.0.0'),
    dependency ('epoxy'),
    cc.find_library ('m', required: false),
]

executable (
    meson.project_name(),
    sources: shadertoy_sources,
    dependencies: shadertoy_dependencies,
    install: true,
)