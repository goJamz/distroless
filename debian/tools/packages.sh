#!/bin/sh

set -eu

TOOLS_DIR=$(dirname -- "$0")
. "${TOOLS_DIR}/cdso_tools.sh"

# get_stats <package>
get_stats() {
    info "Searching package cache for $1"
    stats=$(apt-cache show "$1" --no-all-versions 2>/dev/null)
    ver=$(printf '%s\n' "$stats" | awk '/^Version: / { print $2; exit }')
    sha=$(printf '%s\n' "$stats" | awk '/^SHA256: / { print $2; exit }')
    name=$(printf '%s\n' "$stats" | awk -F/ '/^Filename: / { print $NF; exit }')

    if [ -z "$ver" ] || [ -z "$sha" ] || [ -z "$name" ]; then
        fail "Failed to get package information for $1"
    fi
    success "Found version: $ver"
}

# download <package> <version> <filename>
download() {
    info "Downloading $1 $2"
    apt-get download -qq "$1=$2"
    if [ ! -f "$3" ]; then
        fail "Failed to download $3"
    fi
    success "Downloaded $3"
}

# check_hash <filename> <expected hash>
check_hash() {
    pkg_hash=$(sha256sum "$1" | awk '{ print $1 }')
    if [ "$pkg_hash" != "$2" ]; then
        fail "Hash verification failed for $1"
    fi
    success "Verified $1"
}

# extract_deb <filename> <output directory>
extract_deb() {
    info "Extracting $1"
    dpkg-deb --extract "$1" "$2" || fail "Failed to extract $1"
}

# record_package <filename> <output directory>
record_package() {
    status_file="$2/var/lib/dpkg/status"
    mkdir -p "$(dirname -- "$status_file")"
    {
        dpkg-deb --field "$1" Package Version Architecture
        echo "Status: install ok installed"
        echo
    } >> "$status_file"
}

# collect_packages <package> ...
collect_packages() {
    original_dir=$(pwd)
    download_dir=$(mktemp -d)
    package_dir=$(mktemp -d)
    chown _apt:root "$download_dir"
    cd "$download_dir"

    packages=$(
        apt-cache depends --recurse \
            --no-recommends \
            --no-suggests \
            --no-conflicts \
            --no-breaks \
            --no-replaces \
            --no-enhances \
            "$@" \
            | awk '/^[[:alnum:]][[:alnum:].+:-]*$/ && $0 !~ /^</ { print }' \
            | sort -u
    )

    for package in $packages; do
        get_stats "$package"
        download "$package" "$ver" "$name"
        check_hash "$name" "$sha"
        extract_deb "$name" "$package_dir"
        record_package "$name" "$package_dir"
    done

    cd "$original_dir"
    info "Packaging extracted files"
    tar -C "$package_dir" -czf packages.tgz . || fail "Failed to create packages.tgz"
}

make_symlinks() {
    link_dir=$(mktemp -d)
    for link in lib lib64 bin sbin; do
        ln -s "/usr/$link" "$link_dir/$link"
    done
    tar -C "$link_dir" -czf symlinks.tgz lib lib64 bin sbin \
        || fail "Failed to create symlinks.tgz"
}

info "Refreshing package metadata"
apt-get -qq update

if [ "${CI_COMMIT_TAG:-debian-static}" = "debian-static" ]; then
    collect_packages netbase
else
    collect_packages netbase libc6
fi

make_symlinks
