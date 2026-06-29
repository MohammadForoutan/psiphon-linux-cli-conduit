# Prebuilt Psiphon tunnel core binaries do not ship GNU build-ids.
%global _missing_build_ids_terminate_build 0

Name:           psiphon-cli-gui
Version:        %{version}
Release:        1%{?dist}
Summary:        Native Linux GUI for Psiphon tunnel core
License:        MIT
URL:            https://github.com/MohammadForoutan/psiphon-linux-cli-conduit
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  meson >= 0.59
BuildRequires:  vala
BuildRequires:  gcc
BuildRequires:  gtk4-devel >= 4.6
BuildRequires:  libadwaita-devel >= 1.2
BuildRequires:  json-glib-devel
BuildRequires:  glib2-devel
BuildRequires:  nodejs >= 18

Requires:       gtk4 >= 4.6
Requires:       libadwaita >= 1.2
Requires:       json-glib
Requires:       glib2

%description
Psiphon CLI GUI is a native GTK4/libadwaita desktop application that manages
psiphon-tunnel-core directly. This package installs the GUI, bundled config
assets, psiphon-tunnel-core, sing-box (for optional TUN routing), and GSettings
defaults for the bundled binary paths.

%prep
%autosetup -n %{name}-%{version}

%build
test -x sing-box
test -f libcronet.so
test -s configs/server_list_compressed
export PSIPHON_SERVER_LIST=%{_builddir}/%{name}-%{version}/configs/server_list_compressed
node scripts/bundle-server-list.js --repo-only
cd gui
%meson --prefix=%{_prefix}
%meson_build

%install
cd gui
%meson_install
install -D -m 755 ../psiphon-tunnel-core-x86_64 \
  %{buildroot}%{_libdir}/psiphon-cli-gui/psiphon-tunnel-core-x86_64
install -D -m 755 ../sing-box \
  %{buildroot}%{_libdir}/psiphon-cli-gui/sing-box
install -D -m 755 ../libcronet.so \
  %{buildroot}%{_libdir}/psiphon-cli-gui/libcronet.so
install -D -m 755 ../packaging/rpm/init-psiphon-core.sh \
  %{buildroot}%{_libexecdir}/psiphon-cli-gui/init-psiphon-core.sh
install -D -m 755 ../packaging/rpm/init-psiphon-server-list.sh \
  %{buildroot}%{_libexecdir}/psiphon-cli-gui/init-psiphon-server-list.sh
install -D -m 755 ../packaging/rpm/init-sing-box.sh \
  %{buildroot}%{_libexecdir}/psiphon-cli-gui/init-sing-box.sh

%post
%{_libexecdir}/psiphon-cli-gui/init-psiphon-core.sh %{_libdir} || :
%{_libexecdir}/psiphon-cli-gui/init-sing-box.sh %{_libdir} || :
%{_libexecdir}/psiphon-cli-gui/init-psiphon-server-list.sh %{_datadir} || :
%{_bindir}/glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :

%postun
%{_bindir}/glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :

%files
%{_bindir}/psiphon-cli-gui
%{_libdir}/psiphon-cli-gui/psiphon-tunnel-core-x86_64
%{_libdir}/psiphon-cli-gui/sing-box
%{_libdir}/psiphon-cli-gui/libcronet.so
%{_libexecdir}/psiphon-cli-gui/init-psiphon-core.sh
%{_libexecdir}/psiphon-cli-gui/init-sing-box.sh
%{_libexecdir}/psiphon-cli-gui/init-psiphon-server-list.sh
%{_datadir}/applications/io.github.MohammadForoutan.PsiphonCliGui.desktop
%{_datadir}/metainfo/io.github.MohammadForoutan.PsiphonCliGui.metainfo.xml
%{_datadir}/glib-2.0/schemas/io.github.MohammadForoutan.PsiphonCliGui.gschema.xml
%{_datadir}/glib-2.0/schemas/io.github.MohammadForoutan.PsiphonCliGui.gschema.override
%{_datadir}/psiphon-cli-gui/

%changelog
* Wed May 27 2026 Psiphon CLI GUI Packagers <packaging@localhost> - %{version}-1
- Bundle psiphon-tunnel-core, sing-box, and libcronet.so for TUN routing
