#!/bin/sh

TOOLS_DIR=$(dirname -- "$0")
. ${TOOLS_DIR}/cdso_tools.sh

# get_stats <pkg name>
get_stats() {
    info "Searching package cache for $1"
    stats=$(apt-cache show $1 --no-all-versions 2>/dev/null)
    ver=$(echo "$stats" | grep Version | cut -d' ' -f2)
    sha=$(echo "$stats" | grep SHA256 | cut -d' ' -f2)
    name=$(echo "$stats" | grep Filename | rev | cut -d'/' -f1 | rev)
    if test -z "$ver" || test -z "$sha"; then
        fail "Failed to get package information"
    else
        success "Found version: $ver"
    fi
}

# download <pkg name> <version> <filename>
download () {
    info "Downloading $1 $2"
    apt-get download -qq "$1=$2"
    if test -f "$3"; then
        success "Downloaded $3"
    else
        fail "Failed to download"
    fi
}

# check_hash <filename> <expected_hash>
check_hash() {
	pkg_hash=$(sha256sum $1 | cut -d' ' -f1)
    info "Expected hash: $2"
	info "Package hash: $pkg_hash"
	if [ "$pkg_hash" = "$2" ]; then
        success "Verified hash"
    else
		fail "Hashes do not match"
	fi
}

# extract_deb <filename> <output dir>
extract_deb() {
    info "Extracting $1"
    ar x $1 && \
    data=$(find . -name "data.tar.*")
    if [ "$data" = "./data.tar.xz" ]; then
        tar -C $2 -xf $data
    elif [ "$data" = "./data.tar.zst" ]; then
        tar -C $2 --use-compress-program=unzstd -xf $data
    else
        fail "Can't extract $data"
    fi

    if [ $? != 0 ]; then
        fail "Failed to extract"
    else
        rm -f $data
    fi
}

# package_debs <workdir> <new pkg>
package_debs() {
    info "Packaging all files into $2"
    tar -C $1 -czf $2 .
    if [ $? != 0 ]; then
        fail "Error repacking"
    fi
}

# collect_packages <name> ...
collect_packages() {
    cwd=$(pwd)
    tmpdir=$(mktemp -d)
    workdir=$(mktemp -d)
    chown _apt:root $tmpdir && cd $tmpdir
    for pkg in $*; do
        get_stats $pkg
        download $pkg $ver $name
        check_hash $name $sha
        extract_deb $name $workdir
        echo
    done

    cd $cwd
    package_debs $workdir packages.tgz
}

# ubuntu has symbolic links that binaries use
# to find linked libraries and other binaries
make_symlinks() {
  symlinks="lib lib64 bin sbin"
  for sl in ${symlinks}; do
    ln -s /usr/${sl} ${sl}
  done
  tar -czf symlinks.tgz ${symlinks}
}

info "Installing dependencies..."
apt-get -qq update && \
apt-get -qq install --no-install-recommends binutils xz-utils zstd
if test $? -ne 0; then
    fail "Could not install dependencies"
fi

if [ "${CI_COMMIT_TAG:-ubuntu-static}" = "ubuntu-static" ]; then
    collect_packages netbase
else
    collect_packages netbase libc6
fi

make_symlinks