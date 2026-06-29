desktop_conf = configuration_data()
desktop_conf.set('bindir', get_option('prefix') / get_option('bindir'))

desktop_file = configure_file(
  input: 'io.github.MohammadForoutan.PsiphonCliGui.desktop.in',
  output: 'io.github.MohammadForoutan.PsiphonCliGui.desktop',
  configuration: desktop_conf,
)

install_data(
  desktop_file,
  install_dir: get_option('datadir') / 'applications',
)

install_data(
  'io.github.MohammadForoutan.PsiphonCliGui.metainfo.xml.in',
  rename: 'io.github.MohammadForoutan.PsiphonCliGui.metainfo.xml',
  install_dir: get_option('datadir') / 'metainfo',
)

schema_file = 'io.github.MohammadForoutan.PsiphonCliGui.gschema.xml'
core_libdir = get_option('libdir') / 'psiphon-cli-gui'
core_install_path = get_option('prefix') / core_libdir / 'psiphon-tunnel-core-x86_64'
sing_box_install_path = get_option('prefix') / core_libdir / 'sing-box'

install_data(
  schema_file,
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

override_conf = configuration_data()
override_conf.set('core_path', core_install_path)
override_conf.set('sing_box_path', sing_box_install_path)
install_data(
  configure_file(
    input: 'io.github.MohammadForoutan.PsiphonCliGui.gschema.override.in',
    output: 'io.github.MohammadForoutan.PsiphonCliGui.gschema.override',
    configuration: override_conf,
  ),
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

gnome.compile_schemas(
  build_by_default: true,
  depend_files: files(
    schema_file,
    'io.github.MohammadForoutan.PsiphonCliGui.gschema.override.in',
  ),
)

fs = import('fs')
core_source = project_root / 'psiphon-tunnel-core-x86_64'
if fs.exists(core_source)
  install_data(
    core_source,
    install_dir: core_libdir,
    install_mode: 'rwxr-xr-x',
    rename: 'psiphon-tunnel-core-x86_64',
  )
endif

sing_box_source = project_root / 'sing-box'
if fs.exists(sing_box_source)
  install_data(
    sing_box_source,
    install_dir: core_libdir,
    install_mode: 'rwxr-xr-x',
    rename: 'sing-box',
  )
endif

libcronet_source = project_root / 'libcronet.so'
if fs.exists(libcronet_source)
  install_data(
    libcronet_source,
    install_dir: core_libdir,
    install_mode: 'rwxr-xr-x',
    rename: 'libcronet.so',
  )
endif
