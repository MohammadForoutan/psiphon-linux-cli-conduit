project(
  'psiphon-cli-gui',
  ['vala', 'c'],
  version: '0.1.0',
  meson_version: '>=0.59.0',
)

gnome = import('gnome')

node = find_program('node')
project_root = meson.project_source_root() / '..'

bundle_stamp = custom_target(
  'bundle-server-list',
  output: 'bundle-server-list.stamp',
  command: [node, project_root / 'scripts' / 'bundle-server-list.js', '@OUTPUT@'],
  build_by_default: true,
)

version_json = custom_target(
  'generate-version',
  output: 'version.json',
  command: [node, project_root / 'scripts' / 'generate-version.js', '--gui-output', '@OUTPUT@'],
  build_by_default: true,
  install: true,
  install_dir: get_option('datadir') / 'psiphon-cli-gui',
)

deps = [
  dependency('gtk4', version: '>=4.6'),
  dependency('libadwaita-1', version: '>=1.2'),
  dependency('json-glib-1.0'),
  dependency('gio-2.0'),
  dependency('glib-2.0'),
]

sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/window.vala',
  'src/widgets/connection-panel.vala',
  'src/widgets/settings-dialog.vala',
  'src/widgets/logs-dialog.vala',
  'src/widgets/stats-panel.vala',
  'src/services/config-service.vala',
  'src/services/settings-service.vala',
  'src/services/log-service.vala',
  'src/services/ip-service.vala',
  'src/services/server-list-service.vala',
  'src/services/notice-parser.vala',
  'src/services/stats-service.vala',
  'src/services/tunnel-manager.vala',
  'src/services/system-proxy-service.vala',
  'src/services/sing-box-manager.vala',
  'src/models/protocol-mode.vala',
  'src/models/region.vala',
  'src/models/tunnel-options.vala',
  'src/models/tunnel-stats.vala',
  'src/utils/constants.vala',
  'src/utils/format.vala',
  'src/utils/gsettings-setup.vala',
  'src/utils/runtime-paths.vala',
  'src/utils/region-flags.vala',
  'src/utils/version-info.vala',
  'src/widgets/about-dialog.vala',
)

executable(
  'psiphon-cli-gui',
  sources,
  bundle_stamp,
  version_json,
  dependencies: deps,
  install: true,
)

fs = import('fs')
config_assets = [
  '../configs/psiphon.config',
]
list_source = project_root / 'configs' / 'server_list_compressed'
if fs.exists(list_source)
  config_assets += '../configs/server_list_compressed'
endif

install_data(
  config_assets,
  install_dir: get_option('datadir') / 'psiphon-cli-gui' / 'configs',
)

if fs.exists(list_source)
  install_data(
    list_source,
    install_dir: get_option('datadir') / 'psiphon-cli-gui' / 'configs',
    rename: 'remote_server_list',
  )
endif

subdir('data')

summary('Psiphon core install path', get_option('prefix') / get_option('libdir') / 'psiphon-cli-gui' / 'psiphon-tunnel-core-x86_64', section: 'Paths')
