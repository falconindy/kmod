project('kmod', 'c',
        version : '27',
        license : 'LGPLv2.1',
        meson_version : '>=0.53',
        default_options : [
          'c_std=gnu99',
          'warning_level=2',
          'prefix=/usr',
          'sysconfdir=/etc',
          'localstatedir=/var',
        ])

libkmod_version = '2.3.5'

rootlibdir = get_option('rootlibdir')
if rootlibdir == ''
  rootlibdir = get_option('libdir')
endif

cdata = configuration_data()
cdata.set10('_GNU_SOURCE', true)
cdata.set_quoted('PACKAGE', meson.project_name())
cdata.set_quoted('VERSION', meson.project_version())
cdata.set_quoted('SYSCONFDIR', get_option('sysconfdir'))
cdata.set10('ENABLE_LOGGING', get_option('logging'))
cdata.set10('ENABLE_DEBUG', get_option('kmod-debug'))

cc = meson.get_compiler('c')

add_project_arguments(
  cc.get_supported_arguments([
    '-Wno-inline',
    '-Wvla',
    '-Wundef',
    '-Wformat=2',
    '-Wlogical-op',
    '-Wsign-compare',
    '-Wformat-security',
    '-Wmissing-include-dirs',
    '-Wformat-nonliteral',
    '-Wold-style-definition',
    '-Wpointer-arith',
    '-Winit-self',
    '-Wdeclaration-after-statement',
    '-Wfloat-equal',
    '-Wmissing-prototypes',
    '-Wstrict-prototypes',
    '-Wredundant-decls',
    '-Wmissing-declarations',
    '-Wmissing-noreturn',
    '-Wshadow',
    '-Wendif-labels',
    '-Wstrict-aliasing=3',
    '-Wwrite-strings',
    '-Wno-long-long',
    '-Wno-overlength-strings',
    '-Wno-unused-parameter',
    '-Wno-missing-field-initializers',
    '-Wno-unused-result',
    '-Wnested-externs',
    '-Wchar-subscripts',
    '-Wtype-limits',
    '-Wuninitialized',
    '-fno-common',
    '-fdiagnostics-show-option',
    '-ffunction-sections',
    '-fdata-sections',
  ]),
  language : 'c')

add_project_link_arguments(
  cc.get_supported_link_arguments([
    '-Wl,--gc-sections',
  ]),
  language : 'c')

foreach header : ['linux/module.h'
                  ]
  if cc.has_header(header)
    cdata.set('HAVE_@0@'.format(header.underscorify().to_upper()), true)
  endif
endforeach

foreach tuple : [['__xstat', ''],
                 ['__secure_getenv', ''],
                 ['secure_getenv', ''],
                 ['finit_module', '#include <linux/module.h>'],
                 ]
  sym = tuple[0]
  prefix = tuple[1]
  if cc.has_function(sym, prefix : prefix, args : '-D_GNU_SOURCE')
    cdata.set('HAVE_@0@'.format(sym.to_upper()), true)
  endif
endforeach

foreach tuple : [['strndupa', '#include <string.h>'],
                 ['be32toh', '#include <endian.h>'],
                 ]
  decl = tuple[0]
  prefix = tuple[1]
  have = cc.has_function(decl, prefix : prefix, args : '-D_GNU_SOURCE')
  cdata.set10('HAVE_DECL_@0@'.format(decl.to_upper()), have)
endforeach

# Meson has some amount of support for finding builtins by passing the symbol
# name without the "__builtin_" prefix to cc.has_function(). In practice, it
# doesn't seem to detect everything we need.
foreach tuple : [['__builtin_clz', '0', true],
                 ['__builtin_types_compatible_p', 'int, int', true],
                 ['__builtin_uaddl_overflow', '0UL, 0UL, (void*)0', false],
                 ['__builtin_uaddll_overflow', '0ULL, 0ULL, (void*)0', false],
                 ]
  builtin = tuple[0]
  args = tuple[1]
  required = tuple[2]
  have = cc.links('int main(void){@0@(@1@);return 0;}'.format(builtin, args))
  if required and not have
    error('required builtin function not found: @0@'.format(builtin))
  endif
  cdata.set10('HAVE_@0@'.format(builtin.to_upper()), have)
endforeach

foreach tuple : [['struct stat', 'st_mtim', '#include <sys/stat.h>']
                 ]
  if cc.has_member(tuple[0], tuple[1], prefix : tuple[2], args : '-D_GNU_SOURCE')
    cdata.set('HAVE_@0@_@1@'.format(tuple[0].underscorify().to_upper(),
                                    tuple[1].underscorify().to_upper()),
              true)
  endif
endforeach

if cc.compiles('_Static_assert(1, "Test")')
  cdata.set('HAVE_STATIC_ASSERT', true)
endif

if cc.compiles('_Noreturn int foo(void) { exit(0); }')
  cdata.set('HAVE_NORETURN', true)
endif

libdl = cc.find_library('dl')

features = []

want_xz = get_option('xz')
if want_xz != 'false'
  libxz = dependency('liblzma',
                     required : want_xz == 'true')
  have = libxz.found()
  cdata.set('ENABLE_XZ', have)
else
  have = false
  libxz = []
endif
features += ['@0@XZ'.format(have ? '+' : '-')]

want_zlib = get_option('zlib')
if want_zlib != 'false'
  libz = dependency('zlib',
                    required : want_zlib == 'true')
  have = libz.found()
  cdata.set('ENABLE_ZLIB', have)
else
  have = false
  libz = []
endif
features += ['@0@ZLIB'.format(have ? '+' : '-')]

want_openssl = get_option('openssl')
if want_openssl != 'false'
  libcrypto = dependency('libcrypto',
                         version : '>= 1.1.0',
                         required : want_openssl == 'true')
  have = libcrypto.found()
  cdata.set('ENABLE_OPENSSL', have)
else
  have = false
  libcrypto = []
endif
features += ['@0@LIBCRYPTO'.format(have ? '+' : '-')]

features += ['@0@EXPERIMENTAL'.format(get_option('experimental') ? '+' : '-')]

cdata.set_quoted('KMOD_FEATURES', ' '.join(features))

config_h = configure_file(
        output : 'config.h',
        configuration : cdata)

add_project_arguments('-include', 'config.h', language : 'c')

# ------------------------------------------------------------------
# libraries and binaries
# ------------------------------------------------------------------

libshared = static_library(
  'shared',
  files('''
    shared/macro.h
    shared/missing.h
    shared/array.c shared/array.h
    shared/hash.c shared/hash.h
    shared/scratchbuf.c shared/scratchbuf.h
    shared/strbuf.c shared/strbuf.h
    shared/util.c shared/util.h
  '''.split()),
  install : false)

libkmod_a = static_library(
  'kmod',
  files('''
    libkmod/libkmod-builtin.c
    libkmod/libkmod-config.c
    libkmod/libkmod-elf.c
    libkmod/libkmod-file.c
    libkmod/libkmod-index.c
    libkmod/libkmod-index.h
    libkmod/libkmod-internal.h
    libkmod/libkmod-list.c
    libkmod/libkmod-module.c
    libkmod/libkmod-signature.c
    libkmod/libkmod.c libkmod/libkmod.h
  '''.split()))

libkmod_deps = [
  libcrypto,
  libxz,
  libz,
]

libkmod = shared_library(
  'kmod',
  objects : libkmod_a.extract_all_objects(),
  dependencies : libkmod_deps,
  version : libkmod_version,
  gnu_symbol_visibility : 'hidden',
  link_with : [libshared],
  link_args : ['-Wl,--version-script=@0@/libkmod/libkmod.sym'.format(
      meson.source_root())],
  link_depends : files('libkmod/libkmod.sym'),
  install : true)

install_headers('libkmod/libkmod.h')

import('pkgconfig').generate(
  libkmod,
  name : 'libkmod',
  requires_private : libkmod_deps,
  description : 'Library to deal with kernel modules')

kmod_sources = files('''
  tools/depmod.c
  tools/insmod.c
  tools/kmod.c tools/kmod.h
  tools/log.c tools/log.h
  tools/lsmod.c
  tools/modinfo.c
  tools/modprobe.c
  tools/rmmod.c
  tools/static-nodes.c
'''.split())

if get_option('experimental')
  kmod_sources += files('''
    tools/insert.c
    tools/remove.c
  '''.split())
endif

kmod = executable(
  'kmod',
  kmod_sources,
  link_whole : [libshared, libkmod_a],
  dependencies : libkmod_deps,
  build_by_default : get_option('tools'),
  install : true)

# XXX: tools/meson.build creates internal symlinks for the various multi-call
# names of kmod. this makes the testsuite happy because it hardcodes the 'tools/'
# portion of the path to the built tool. we can make this nicer once autotools
# goes away.
subdir('tools')

# ------------------------------------------------------------------
# tests
# ------------------------------------------------------------------

testsuite_c_args = [
  '-DTESTSUITE_ROOTFS="@0@/testsuite/rootfs/"'.format(meson.build_root()),
  '-DABS_TOP_BUILDDIR="@0@"'.format(meson.build_root()),
  '-DOVERRIDE_LIBDIR="@0@/"'.format(meson.build_root()),
  '-DOVERRIDE_LIBPREFIX="lib"',
]

# XXX: we should supply a depfile dynamically generated by rootfs creation to
# only rebuild this when necessary.
create_rootfs = custom_target(
  'create_rootfs',
  command : [
    find_program('build-aux/create-rootfs.sh'),
    meson.source_root(),
    meson.build_root(),
  ],
  output : ['stamp-rootfs'],
  build_always_stale : true,
  build_by_default : true)

foreach mod : ['delete_module',
               'init_module',
               'path',
               'uname',
               ]
  shared_module(
    '@0@'.format(mod),
    files('testsuite/@0@.c'.format(mod)),
    c_args : testsuite_c_args,
    build_rpath : '/nowhere',
    dependencies : [libdl, libkmod_deps],
    link_with : [libshared, libkmod_a],
    build_by_default : true)
endforeach

libtestsuite = static_library(
  'testsuite',
  files('''
    testsuite/testsuite.c testsuite/testsuite.h
  '''.split()),
  c_args : testsuite_c_args,
  link_with : [libkmod_a],
  dependencies : libkmod_deps,
  install : false)

foreach input : ['test-hash',
                 'test-array',
                 'test-scratchbuf',
                 'test-strbuf',
                 'test-init',
                 'test-initstate',
                 'test-testsuite',
                 'test-loaded',
                 'test-modinfo',
                 'test-util',
                 'test-new-module',
                 'test-modprobe',
                 'test-blacklist',
                 'test-dependencies',
                 'test-depmod',
                 'test-list',
                 ]
  test(
    input,
    executable(
      input,
      files('testsuite/@0@.c'.format(input)),
      c_args : testsuite_c_args,
      link_with : [libkmod_a, libshared, libtestsuite],
      export_dynamic : true),
    depends : [create_rootfs])
endforeach

# ------------------------------------------------------------------
# python
# ------------------------------------------------------------------

subdir('libkmod/python')

# ------------------------------------------------------------------
# documentation
# ------------------------------------------------------------------
if get_option('manpages')
  xsltproc = find_program('xsltproc', required : false)
  if not xsltproc.found()
    error('manpage support requested but xsltproc program not found')
  endif

  foreach tuple : [
      [ '5',
        {
          'pages' : [
            'depmod.d',
            'modprobe.d',
            'modules.dep',
          ],
          'aliases' : [
            # stub name          points to
            [ 'modules.dep.bin', 'modules.dep' ]
          ],
        }
      ],
      [ '8',
        {
          'pages' : [
            'depmod',
            'insmod',
            'kmod',
            'lsmod',
            'modinfo',
            'modprobe',
            'rmmod',
          ],
        }
      ],
    ]
    section = tuple[0]

    foreach man : tuple[1].get('pages')
      input = 'man/@0@.xml'.format(man)
      output = '@0@.@1@'.format(man, section)

      custom_target(
        'man_@0@_@1@'.format(section, man),
        output : [output],
        input : [input],
        command : [
          xsltproc,
          '-o', '@OUTPUT@',
          '--nonet',
          '--stringparam', 'man.output.quietly', '1',
          '--param', 'funcsynopsis.style', '"ansi"',
          'http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl',
          '@INPUT@',
        ],
        build_by_default : true,
        install : true,
        install_dir : join_paths(get_option('mandir'), 'man@0@'.format(section)))
    endforeach

    foreach tuple : tuple[1].get('aliases', [])
      man = tuple[0]
      dest = tuple[1]
      output = '@0@.@1@'.format(man, section)

      custom_target(
        man,
        output : [output],
        command : ['echo', '.so man@0@/@1@.@0@'.format(section, dest)],
        capture : true,
        install : true,
        install_dir : join_paths(get_option('mandir'), 'man@0@'.format(section)))
    endforeach
  endforeach
endif

mkdir_p = 'mkdir -p $DESTDIR/@0@'
foreach confdir : ['modprobe.d', 'depmod.d']
  meson.add_install_script(
    'sh', '-c', mkdir_p.format(get_option('sysconfdir') / confdir))
  meson.add_install_script(
    'sh', '-c', mkdir_p.format(get_option('prefix') / get_option('libdir') / confdir))
endforeach

bashcompletion = dependency('bash-completion', required : false)
if bashcompletion.found()
  bashcompdir = bashcompletion.get_pkgconfig_variable('completionsdir')
else
  bashcompdir = get_option('prefix') / get_option('datadir') / 'bash-completion/completions'
endif

install_data(
  files('shell-completion/bash/kmod'),
  install_dir : bashcompdir)

summary({
  'prefix'      : get_option('prefix'),
  'sysconfdir'  : get_option('prefix') / get_option('sysconfdir'),
  'libdir'      : get_option('prefix') / get_option('libdir'),
  'rootlibdir'  : get_option('prefix') / rootlibdir,
  'includedir'  : get_option('prefix') / get_option('includedir'),
  'bindir'      : get_option('prefix') / get_option('bindir'),
}, section : 'Directories')

summary({
  'tools' : get_option('tools'),
  'python bindings' : get_option('python'),
  'logging' : get_option('tools'),
  'debug' : get_option('kmod-debug'),
  'doc' : get_option('doc'),
  'man' : get_option('manpages'),
  'test-modules' : get_option('test-modules'),
  'features' : ' '.join(features)
}, section : 'Features')
