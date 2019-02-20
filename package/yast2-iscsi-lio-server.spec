#
# spec file for package yast2-iscsi-lio-server
#
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-iscsi-lio-server
Version:        4.0.12
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  rubygem(%rb_default_ruby_abi:rspec)
BuildRequires:  rubygem(%rb_default_ruby_abi:yast-rake)
Requires:       python3-configshell-fb
Requires:       python3-rtslib-fb
Requires:       python3-targetcli-fb

#Replace SuSEFirewall2 by firewalld
Requires:       yast2 >= 4.0.39

BuildArch:      noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        Configuration of iSCSI LIO target
License:        GPL-2.0
Group:          System/YaST

%description
This package contains configuration of iSCSI LIO target

%prep
%setup -n %{name}-%{version}

%build

%check
rake test:unit

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/iscsi-lio-server
%{yast_yncludedir}/iscsi-lio-server/*
%{yast_clientdir}/iscsi-lio-server.rb
%{yast_desktopdir}/iscsi-lio-server.desktop
%doc %{yast_docdir}

%changelog
