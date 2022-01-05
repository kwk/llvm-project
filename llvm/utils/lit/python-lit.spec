# The following tag is to get correct syntax highlighting for this file in vim text editor
# vim: syntax=spec

# See https://docs.pagure.org/rpkg-util/v3/macro_reference.html#macro-reference-v3


%bcond_without check

{{{llvm_snapshot_prefix}}}

# git_dir_name returns repository name derived from remote Git repository URL
Name: python-lit

# Basic description of the package
Summary: Tool for executing llvm test suites
Version: %{llvm_snapshot_version}~%{llvm_snapshot_version_suffix}


# This can be useful later for adding downstream patches
Release:    1%{?dist}

BuildArch: noarch

License: NCSA

# Home page of the project. Can also point to the public Git repository page.
URL: https://src.fedoraproject.org/forks/kkleine/rpms/llvm.git

# Source is created by:
# rpkg spec --sources
Source0: {{{git_cwd_archive}}}

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

# prep will extract the tarball defined as Source above and descend into it.
%prep
{{{ git_cwd_setup_macro }}}

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
%{?llvm_snapshot_changelog_entry}

* Thu Oct 21 2021 Konrad Kleine <kkleine@redhat.com> - 13.0.0-2
- Remove python 2 support