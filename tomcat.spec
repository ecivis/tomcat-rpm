%define major_version 7
%define minor_version 0
%define micro_version 47
%define appname tomcat
%define distname %{name}-%{version}

%define basedir %{_var}/lib/%{appname}
%define appdir %{basedir}/webapps
%define bindir %{_datadir}/%{appname}/bin
%define libdir %{_datadir}/%{appname}/lib
%define confdir %{_sysconfdir}/%{appname}
%define homedir %{_datadir}/%{appname}
%define logdir %{_var}/log/%{appname}
%define piddir %{_var}/run/%{appname}
%define cachedir %{_var}/cache/%{appname}
%define tempdir %{cachedir}/temp
%define workdir %{cachedir}/work

%define appuser tomcat
%define appuid 91
%define appgid 91


Name: apache-tomcat
Version: %{major_version}.%{minor_version}.%{micro_version}
Release: 1%{?dist}
Epoch: 0
Summary: Open source software implementation of the Java Servlet and JavaServer Pages technologies.
Group: Networking/Daemons
License: ASL 2.0
URL: http://tomcat.apache.org
Packager: Joseph Lamoree <jlamoree@ecivis.com>
Source0: http://www.apache.org/dist/tomcat/tomcat-%{major_version}/v%{version}/bin/%{name}-%{version}.tar.gz
Source1: tomcat.sysconfig
Source2: tomcat.init.sh
Source3: tomcat.logrotate.sh
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch


%description
Tomcat is the servlet container that is used in the official Reference
Implementation for the Java Servlet and JavaServer Pages technologies.
The Java Servlet and JavaServer Pages specifications are developed by
Sun under the Java Community Process.


%package manager
Summary: The management web application of Apache Tomcat.
Group: System Environment/Applications
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description manager
The management web application of Apache Tomcat.


%package host-manager
Summary: The host-management web application of Apache Tomcat.
Group: System Environment/Applications
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description host-manager
The host-management web application of Apache Tomcat.


%prep
%setup -q -b 0 -T


%build


%install
rm -rf %{buildroot}
%{__install} -d -m 0755 %{buildroot}%{_bindir}
%{__install} -d -m 0755 %{buildroot}%{_sbindir}
%{__install} -d -m 0755 %{buildroot}%{_initrddir}
%{__install} -d -m 0755 %{buildroot}%{_sysconfdir}/logrotate.d
%{__install} -d -m 0755 %{buildroot}%{_sysconfdir}/sysconfig
%{__install} -d -m 0775 %{buildroot}%{appdir}
%{__install} -d -m 0755 %{buildroot}%{bindir}
%{__install} -d -m 0755 %{buildroot}%{libdir}
%{__install} -d -m 0755 %{buildroot}%{confdir}
%{__install} -d -m 0775 %{buildroot}%{confdir}/Catalina/localhost
%{__install} -d -m 0775 %{buildroot}%{logdir}
%{__install} -d -m 0775 %{buildroot}%{piddir}
%{__install} -d -m 0775 %{buildroot}%{homedir}
%{__install} -d -m 0775 %{buildroot}%{tempdir}
%{__install} -d -m 0775 %{buildroot}%{workdir}

pushd %{buildroot}/%{homedir}
    %{__ln_s} %{appdir} webapps
    %{__ln_s} %{confdir} conf
    %{__ln_s} %{logdir} logs
    %{__ln_s} %{tempdir} temp
    %{__ln_s} %{workdir} work
popd

pushd %{buildroot}/%{basedir}
    %{__ln_s} %{confdir} conf
    %{__ln_s} %{logdir} logs
    %{__ln_s} %{tempdir} temp
    %{__ln_s} %{workdir} work
popd

%{__install} -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/sysconfig/%{appname}
%{__install} -m 0755 %{SOURCE2} %{buildroot}%{_initrddir}/%{appname}
%{__install} -m 0644 %{SOURCE3} %{buildroot}%{_sysconfdir}/logrotate.d/%{appname}

%{__cp} -a bin/*.{jar,xml} %{buildroot}%{bindir}
%{__cp} -a bin/*.sh %{buildroot}%{bindir}
%{__cp} -a conf/*.{policy,properties,xml} %{buildroot}%{confdir}
%{__cp} -a lib/*.jar %{buildroot}%{libdir}
%{__cp} -a webapps/{ROOT,manager,host-manager} %{buildroot}%{appdir}


%clean
%{__rm} -rf %{buildroot}


%pre
%{_sbindir}/groupadd -g %{appgid} -r %{appuser} 2>/dev/null || :
%{_sbindir}/useradd -c "Apache Tomcat" -u %{appuid} -g %{appuser} -s /bin/sh -r -d %{homedir} %{appuser} 2>/dev/null || :


%post
/sbin/chkconfig --add %{appname}


%preun
%{__rm} -rf %{workdir}/* %{tempdir}/*
if [ "$1" = "0" ]; then
  %{_initrddir}/%{appname} stop >/dev/null 2>&1
  /sbin/chkconfig --del %{appname}
fi


# RPM 4.8 has a bug in defattr() with dir mode
%files
#%defattr(0644 root root 0755)
%doc ./{LICENSE,NOTICE,RELEASE*}
%attr(0775 root tomcat) %dir %{logdir}
%attr(0775 tomcat tomcat) %dir %{piddir}
%attr(0755 root root) %{_initrddir}/%{appname}
%attr(0644 root root) %config(noreplace) %{_sysconfdir}/logrotate.d/%{appname}
%config(noreplace) %{_sysconfdir}/sysconfig/%{appname}
%dir %{basedir}
%{basedir}/conf
%{basedir}/logs
%{basedir}/temp
%{basedir}/work
%attr(0775 root tomcat) %dir %{appdir}
%{appdir}/ROOT
%dir %{confdir}
%dir %{confdir}/Catalina
%attr(0775 root tomcat) %dir %{confdir}/Catalina/localhost
%config(noreplace) %{confdir}/*.policy
%config(noreplace) %{confdir}/*.properties
%config(noreplace) %{confdir}/context.xml
%config(noreplace) %{confdir}/server.xml
%attr(0660 root tomcat) %config(noreplace) %{confdir}/tomcat-users.xml
%config(noreplace) %{confdir}/web.xml
%attr(0775 root tomcat) %dir %{cachedir}
%attr(0775 root tomcat) %dir %{tempdir}
%attr(0775 root tomcat) %dir %{workdir}
%attr(- root root) %{homedir}


%files manager
%defattr(0644 root root 0755)
%{appdir}/manager


%files host-manager
%defattr(0644 root root 0755)
%{appdir}/host-manager


%changelog
* Fri Nov 30 2012 Joseph Lamoree <jlamoree@ecivis.com> - 7.0.33-1%{?dist}
- First packaging of Apache Tomcat for eCivis apps
- TODO Tomcat native connector
- TODO Support for multiple instances

