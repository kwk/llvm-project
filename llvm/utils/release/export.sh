#!/bin/bash
#===-- tag.sh - Tag the LLVM release candidates ----------------------------===#
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===------------------------------------------------------------------------===#
#
# Create branches and release candidates for the LLVM release.
#
#===------------------------------------------------------------------------===#

set -e

projects="llvm clang compiler-rt libcxx libcxxabi libclc clang-tools-extra polly lldb lld openmp libunwind flang"

release=""
rc=""
snapshot=""
yyyymmdd=$(date +'%Y%m%d')

usage() {
    echo "Export the Git sources and build tarballs from them"
    echo "usage: `basename $0`"
    echo " "
    echo "  -release <num> The version number of the release"
    echo "  -rc <num>      The release candidate number"
    echo "  -final         The final tag"
    echo "  -snapshot      Use latest revision and append current date (YYYYMMDD) and short git revision to tarballs and their prefixes (no -rc or -release allowed)"
}

export_sources() {
    tag="llvmorg-$release"

    if [ "$rc" = "final" ]; then
        rc=""
    else
        tag="$tag-$rc"
    fi

    llvm_src_dir=$(readlink -f $(dirname "$(readlink -f "$0")")/../../..)
    [ -d $llvm_src_dir/.git ] || ( echo "No git repository at $llvm_src_dir" ; exit 1 )

    release_git_archive_prefix=$release
    release_tarball=$release

    if [ "$snapshot" != "" ]; then
        llvm_version=$(grep -oP 'set\(\s*LLVM_VERSION_(MAJOR|MINOR|PATCH)\s\K[0-9]+' $llvm_src_dir/llvm/CMakeLists.txt | paste -sd '.')
        git_short_rev=$(git rev-parse --short HEAD)
        # For daily snapshots of source tarballs, we want to be able to
        # determine the URL to the source tarball programmatically only from the
        # package name and the current date. Yet, the directory packaged in the
        # tarball should contain the version information of the shared LLVM
        # source tree as well as the git revision. This might be a surprise but
        # a package like clang or compiler-rt don't know about the LLVM version
        # itself. That's why a version encoded in the directory packaged in the
        # tarball can be extremely helpful!
        release_git_archive_prefix=$llvm_version-$yyyymmdd-g$git_short_rev
        release_tarball=$yyyymmdd
        echo $llvm_version > "llvm-version-$yyyymmdd.txt"
        echo "$(git rev-parse --short HEAD)" > "llvm-git-revision-$yyyymmdd.txt"
    fi

    echo $tag
    target_dir=$(pwd)

    echo "Creating tarball for llvm-project ..."
    pushd $llvm_src_dir/
    tree_id=$tag
    if [ "$snapshot" != "" ]; then
        tree_id="HEAD"
    fi
    git archive --prefix=llvm-project-$release_git_archive_prefix$rc.src/ $tree_id . | xz >$target_dir/llvm-project-$release_tarball$rc.src.tar.xz
    popd

    if [ "$snapshot" == "" ]; then
        if [ ! -d test-suite-$release$rc.src ]; then
            echo "Fetching LLVM test-suite source ..."
            mkdir -p test-suite-$release$rc.src
            curl -L https://github.com/llvm/test-suite/archive/$tree_id.tar.gz | \
                tar -C test-suite-$release$rc.src --strip-components=1 -xzf -
        fi
        echo "Creating tarball for test-suite ..."
        tar --sort=name --owner=0 --group=0 \
            --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
            -cJf test-suite-$release$rc.src.tar.xz test-suite-$release$rc.src
    fi

    for proj in $projects; do
        echo "Creating tarball for $proj ..."
        pushd $llvm_src_dir/$proj
        git archive --prefix=$proj-$release_git_archive_prefix$rc.src/ $tree_id . | xz >$target_dir/$proj-$release_tarball$rc.src.tar.xz
        popd
    done
}

while [ $# -gt 0 ]; do
    case $1 in
        -release | --release )
            shift
            release=$1
            ;;
        -rc | --rc )
            shift
            rc="rc$1"
            ;;
        -final | --final )
            rc="final"
            ;;
        -snapshot | --snapshot )
            snapshot="-"
            ;;
        -h | -help | --help )
            usage
            exit 0
            ;;
        * )
            echo "unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ "$snapshot" != "" ]; then 
    if [[ "$rc" != "" || "$release" != "" ]]; then
        echo "error: must not specify rc when creating a snapshot"
        exit 1
    fi
elif [ "x$release" = "x" ]; then
    echo "error: need to specify a release version"
    exit 1
fi

# Make sure umask is not overly restrictive.
umask 0022

export_sources
exit 0
