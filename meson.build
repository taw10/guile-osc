project('guile-osc', ['c'],
        version: '0.1.0',
        license: 'LGPL-2.1-or-later',
        default_options: ['buildtype=debugoptimized'])

# Dependencies
guile_dep = dependency('guile-3.0', required: true)
lo_dep = dependency('liblo', required: true)

# The installation location for Scheme files
guile_sitedir = guile_dep.get_variable('sitedir')
guile_cachedir = guile_dep.get_variable('siteccachedir')

guild = find_program(guile_dep.get_variable('guild'))

scm_files = ['api.scm',
             'client.scm',
             'server-thread.scm',
             'server.scm']

lib = library('guile-osc', ['guile-osc.c'],
              dependencies: [guile_dep, lo_dep],
              install: true)

foreach file : scm_files
    custom_target(file,
                  input: join_paths('open-sound-control', file),
                  output: '@BASENAME@.go',
                  command: [guild, 'compile', '@INPUT@', '-o', '@OUTPUT@',
                            '-L', '@CURRENT_SOURCE_DIR@'],
                  depends: [lib],
                  env: {'GUILE_EXTENSIONS_PATH': meson.current_build_dir()},
                  install: true,
                  install_dir: join_paths(guile_cachedir, 'open-sound-control'))
  endforeach

install_subdir('open-sound-control', install_dir: guile_sitedir)
