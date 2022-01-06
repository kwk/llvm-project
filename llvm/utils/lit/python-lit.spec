# The following tag is to get correct syntax highlighting for this file in vim text editor
# vim: syntax=spec

%bcond_without check

# git_dir_name returns repository name derived from remote Git repository URL
Name:       {{{ git_dir_name name=python-lit }}}

# Basic description of the package
Summary: LLVM lit test runner for Python 3
# git_dir_version returns version based on commit and tag history of the Git project
Version: {{{ git_dir_version lead=1 }}}

# This can be useful later for adding downstream patches
Release:    1%{?dist}

BuildArch: noarch

License: NCSA

# Home page of the project. Can also point to the public Git repository page.
URL: https://src.fedoraproject.org/forks/kkleine/rpms/llvm.git

# Detailed information about the source Git repository and the source commit
# for the created rpm package
VCS:        {{{ git_dir_vcs }}}

# git_dir_pack macro places the repository content (the source files) into a tarball
# and returns its filename. The tarball will be used to build the rpm.
#Source0:    {{{ git_dir_pack }}}

# Source is created by:
# git clone https://github.com/llvm/llvm-project.git
# git checkout {{{ cached_git_name_version }}}
# cd copr/mocks
# rpkg spec --sources
Source0: {{{ git_dir_archive }}}

# for file check
%if %{with check}
BuildRequires: llvm-test
%endif

BuildRequires: python3-devel
BuildRequires: python3-setuptools

%description
lit is a tool used by the LLVM project for executing its test suites.

%package -n python3-lit

Requires: python3-setuptools

%description -n python3-lit
lit is a tool used by the LLVM project for executing its test suites.

# prep will extract the tarball defined as Source above and descend into it.
%prep
{{{ git_dir_setup_macro }}}

%build
%py3_build

%install
%py3_install

# Strip out #!/usr/bin/env python
sed -i -e '1{\@^#!/usr/bin/env python@d}' %{buildroot}%{python3_sitelib}/lit/*.py


%if %{with check}
%check
%{__python3} lit.py tests
%endif

%files -n python3-lit
%license LICENSE.TXT
%doc README.txt
%{python3_sitelib}/*
%{_bindir}/lit

# Finally, changes from the latest release of your application are generated from
# your project's Git history. It will be empty until you make first annotated Git tag.
%changelog
{{{ git_changelog since_tag=FIXME }}}

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
