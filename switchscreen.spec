Name:           switchscreen
Version:        1.0
Release:        1%{?dist}
Summary:        A daemon to monitor for a keyboard shortcut to switch inputs on a Dell Monitor with builtin KVM.
License:        MIT
URL:            https://github.com/drbild/switchscreen
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  libinput-devel
BuildRequires:  libinput-devel
BuildRequires:  systemd-rpm-macros
Requires:       libinput
Requires:       libudev1
Requires(post): systemd
Requires(preun): systemd

%description
A systemd-enabled daemon written in C that for a keyboard shortcut to switch inputs on a Dell Monitor with builtin KVM.

%prep
%setup -q

%build
make

%install
make install DESTDIR=%{buildroot}

%clean
make clean

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%files
/usr/local/bin/%{name}
/usr/local/lib/systemd/system/%{name}.service

%changelog
* Thu Nov 23 2024 David R. Bild <david@davidbild.org> - 1.0-1
- Initial package
