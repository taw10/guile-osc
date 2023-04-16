project('guile-osc', ['c'],
        version: '0.1.0',
        license: 'GPL3+',
        default_options: ['buildtype=debugoptimized'])

# Dependencies
guile_dep = dependency('guile-3.0', required: true)
lo_dep = dependency('liblo', required: true)

# The installation location for Scheme files
guile_sitedir = guile_dep.get_pkgconfig_variable('sitedir')

library('guile-osc', ['guile-osc.c'],
        dependencies: [guile_dep, lo_dep],
        install: true)

install_subdir('open-sound-control', install_dir: guile_sitedir)
