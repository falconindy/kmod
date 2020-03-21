cython = find_program('cython3', required : false)
py3_dep = dependency('python3', required : false)
if get_option('python')
  if not (cython.found() and py3_dep.found())
    error('python support requested but python3 or cython3 not found')
  endif

  py_mod = import('python')
  py = py_mod.find_installation('python3')
  py_dep = dependency('python3')

  foreach pyx : ['_util',
                 'kmod',
                 'list',
                 'module',
                 ]
    cythonized = custom_target(
      '@0@_pyx'.format(pyx),
      input : 'kmod/@0@.pyx'.format(pyx),
      output : '@0@.c'.format(pyx),
      command : [
        cython,
        '@INPUT@',
        '-I', meson.current_source_dir() / 'kmod',
        '-o', '@OUTPUT@',
      ],
      build_by_default : true)
    py.extension_module(
      pyx,
      cythonized,
      dependencies : [py_dep],
      link_with : [libkmod],
      install : true,
      include_directories : ['../..'],
      gnu_symbol_visibility : 'default',
      c_args : [
        '-DCPYTHON_COMPILING_IN_PYPY=0',
        # Remove some warnings for generated code
        '-Wno-redundant-decls',
        '-Wno-shadow',
        '-Wno-strict-aliasing',
      ],
      link_args : [
        # undo our project-wide -Wl,--no-undefined from top-level meson.build
        '-Wl,--unresolved-symbols=ignore-all'
      ],
      subdir : 'kmod')
  endforeach

  cdata = configuration_data()
  cdata.set('VERSION', meson.project_version())

  version_py = configure_file(
    input : 'kmod/version.py.in',
    output : 'version.py',
    configuration : cdata)

  py.install_sources(
    [
      version_py,
      'kmod/__init__.py',
      'kmod/error.py',
    ],
    subdir : 'kmod')
endif
