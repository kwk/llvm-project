# For rpkg macros being used: https://docs.pagure.org/rpkg-util/v3/macro_reference.html#macro-reference-v3

{{{llvm_snapshot_prefix}}}

%global srcname lit

%global lit_version 13.0.0
#global rc_ver 1
#%%global post_ver 1

%global python_lit_srcdir %{srcname}-%{version}%{?rc_ver:rc%{rc_ver}}%{?post_ver:.post%{post_ver}} 

%if %{with snapshot_build}
%undefine rc_ver
%global lit_version %{llvm_snapshot_version}
%endif

%bcond_without check

Name: python-%{srcname}
Version: %{lit_version}%{?rc_ver:~rc%{rc_ver}}%{?llvm_snapshot_version_suffix:~%{llvm_snapshot_version_suffix}}
Release: 2%{?dist}
BuildArch: noarch

License: NCSA
Summary: Tool for executing llvm test suites
URL: https://pypi.python.org/pypi/lit
%if %{without snapshot_build}
Source0: %{pypi_source %{srcname} %{lit_version}%{?rc_ver:rc%{rc_ver}}%{?post_ver:.post%{post_ver}}}
%else
Source0: {{{git_cwd_archive}}}
%endif

# for file check
%if %{with check}
BuildRequires: llvm-test
%endif

BuildRequires: python3-devel
BuildRequires: python3-setuptools

%description
lit is a tool used by the LLVM project for executing its test suites.

%package -n python3-lit
Summary: LLVM lit test runner for Python 3

Requires: python3-setuptools

%description -n python3-lit
lit is a tool used by the LLVM project for executing its test suites.

%prep
%if %{with snapshot_build}
# prep will extract the tarball defined as Source above and descend into it.
{{{ git_cwd_setup_macro }}}
%else
%autosetup -n %{srcname}-%{lit_version}%{?rc_ver:rc%{rc_ver}}%{?post_ver:.post%{post_ver}} -p4
%endif

%build
%py3_build

%install
%py3_install

# Strip out #!/usr/bin/env python
sed -i -e '1{\@^#!/usr/bin/env python@d}' %{buildroot}%{python3_sitelib}/%{srcname}/*.py

%if %{with check} && %{without snapshot_build}
%check
%{__python3} lit.py tests
%endif

%files -n python3-%{srcname}
%license LICENSE.TXT
%doc README.txt
%{python3_sitelib}/*
%{_bindir}/lit

%changelog
%{?llvm_snapshot_changelog_entry}

* Thu Oct 21 2021 Konrad Kleine <kkleine@redhat.com> - 13.0.0-2
- Remove python 2 support

* Tue Oct 05 2021 Tom Stellard <tstellar@redhat.com> - 13.0.0-1
- 13.0.0 Release

* Mon Aug 09 2021 Tom Stellard <tstellar@redhat.com> - 13.0.0~rc1-2
- Add missing dist tag to release

* Fri Aug 06 2021 Tom Stellard <tstellar@redhat.com> - 13.0.0~rc1-1
- 13.0.0-rc1 Release

* Fri Jul 23 2021 Fedora Release Engineering <releng@fedoraproject.org> - 12.0.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_35_Mass_Rebuild

* Wed Jul 14 2021 Tom Stellard <tstellar@redhat.com> - 12.0.1-1
- 12.0.1 Release

* Fri Jun 04 2021 Python Maint <python-maint@redhat.com> - 12.0.0-3
- Rebuilt for Python 3.10

* Fri Jun 04 2021 Python Maint <python-maint@redhat.com> - 12.0.0-2
- Bootstrap for Python 3.10

* Thu May 06 2021 sguelton@redhat.com - 12.0.0-1
- 12.0.0 final release

* Tue Feb 23 2021 Pete Walter <pwalter@fedoraproject.org> - 12.0.0-0.2.rc1
- rebuilt

* Wed Feb 03 2021 sguelton@redhat.com - 12.0.0-0.1.rc1
- 12.0.0 rc1 Release

* Wed Jan 27 2021 Fedora Release Engineering <releng@fedoraproject.org> - 0.11.1-3.rc2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_34_Mass_Rebuild

* Tue Jan 05 2021 sguelton@redhat.com - 0.11.1-2.rc2
- 0.11.1 rc2 Release

* Wed Dec 02 2020 sguelton@redhat.com - 0.11.1-1.rc1
- 0.11.1 rc1 Release

* Sun Oct 25 2020 sguelton@redhat.com - 0.11.0-1
- llvm 11.0.0 - final release

* Fri Oct 09 2020 sguelton@redhat.com - 0.11.0-0.2.rc1
- Correctly ship license

* Fri Aug 07 2020 Tom Stellard <tstellar@redhat.com> - 0.11.0-0.1.rc1
- 0.11.0 rc1 Release

* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Mon May 25 2020 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-3
- Rebuilt for Python 3.9

* Mon May 25 2020 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-2
- Bootstrap for Python 3.9

* Thu Apr 9 2020 sguelton@redhat.com - 0.10.0-1
- 0.10.0 final release

* Tue Feb 11 2020 sguelton@redhat.com - 0.10.0-0.1.rc1
- 0.10.0 rc1 Release

* Thu Jan 30 2020 Fedora Release Engineering <releng@fedoraproject.org> - 0.9.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Fri Sep 20 2019 Tom Stellard <tstellar@redhat.com> - 0.9.0-3
- Re-enable tests

* Fri Sep 20 2019 Tom Stellard <tstellar@redhat.com> - 0.9.0-2
- Disable check to avoid circular dependency with llvm-test

* Fri Sep 20 2019 Tom Stellard <tstellar@redhat.com> - 0.9.0-1
- 0.9.0 Release

* Thu Aug 22 2019 Tom Stellard <tstellar@redhat.com> - 0.9.0-0.1.rc4
- 0.9.0 rc4 Release

* Tue Aug 20 2019 sguelton@redhat.com - 8.0.0-7
- Rebuild for Python 3.8 with test, preparatory work for rhbz#1715016

* Tue Aug 20 2019 sguelton@redhat.com - 8.0.0-6
- Rebuild for Python 3.8 without test, preparatory work for rhbz#1715016

* Mon Aug 19 2019 Miro Hrončok <mhroncok@redhat.com> - 0.8.0-5
- Rebuilt for Python 3.8

* Fri Jul 26 2019 Fedora Release Engineering <releng@fedoraproject.org> - 0.8.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Tue Jul 16 2019 sguelton@redhat.com - 8.0.0-3
- Fix rhbz#1728067

* Fri Jun 28 2019 sguelton@redhat.com - 8.0.0-2
- Fix rhbz#1725155

* Thu Mar 21 2019 sguelton@redhat.com - 8.0.0-1
- 0.8.0 Release

* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 0.7.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Mon Dec 17 2018 sguelton@redhat.com - 0.7.1-1
- 7.0.1 Release

* Tue Sep 25 2018 Tom Stellard <tstellar@redhat.com> - 0.7.0-2
- Add missing dist to release tag

* Fri Sep 21 2018 Tom Stellard <tstellar@redhat.com> - 0.7.0-1
- 0.7.0 Release

* Fri Aug 31 2018 Tom Stellard <tstellar@redhat.com> - 0.7.0-0.2.rc1
- Add Requires: python[23]-setuptools

* Mon Aug 13 2018 Tom Stellard <tstellar@redhat.com> - 0.7.0-0.1.rc1
- 0.7.0 rc1

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.6.0-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 0.6.0-2
- Rebuilt for Python 3.7

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.6.0-1
- 0.6.0 Release

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.6.0-0.2.rc1
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Tue Jan 23 2018 Tom Stellard <tstellar@redhat.com> - 0.6.0-0.1.rc1
- 0.6.0 rc1

* Tue Jan 23 2018 John Dulaney <jdulaney@fedoraproject.org> - 0.5.1-4
- Add a missed python3 conditional around a sed operation

* Mon Jan 15 2018 Merlin Mathesius <mmathesi@redhat.com> - 0.5.1-3
- Cleanup spec file conditionals

* Wed Dec 06 2017 Tom Stellard <tstellar@redhat.com> - 0.5.1-2
- Fix python prefix in BuildRequires

* Tue Oct 03 2017 Tom Stellard <tstellar@redhat.com> - 0.5.1-1
- Rebase to 0.5.1

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.5.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Thu Mar 09 2017 Tom Stellard <tstellar@redhat.com> - 0.5.0-1
- Initial version
