#
# spec file for package yast2-iscsi-lio-server
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
Version:        3.1.16
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
BuildRequires:  docbook-xsl-stylesheets doxygen libxslt popt-devel sgml-skel update-desktop-files yast2 yast2-packagemanager-devel yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  rubygem(rspec)
Requires:       lio-utils

# network needs Wizard::OpenCancelOKDialog()
#  function from yast2-2.18.2
# Wizard::SetDesktopTitleAndIcon()
Requires:       yast2 >= 2.21.22

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	Configuration of iSCSI LIO target

%description
This package contains configuration of iSCSI LIO target

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/iscsi-lio-server
%{yast_yncludedir}/iscsi-lio-server/*
%{yast_clientdir}/iscsi-lio-server.rb
%{yast_clientdir}/iscsi-lio-server_*.rb
%{yast_moduledir}/IscsiLioServer*
%{yast_moduledir}/IscsiLioData*
%{yast_desktopdir}/iscsi-lio-server.desktop
%{yast_scrconfdir}/ietd.scr
%doc %{yast_docdir}
