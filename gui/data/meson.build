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

install_data(
  schema_file,
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

gnome.compile_schemas(
  build_by_default: true,
  depend_files: files(schema_file),
)
