#!/bin/sh

set -eu

TOOLS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${TOOLS_DIR}/cdso_tools.sh"

: "${DEBIAN_VERSION:?DEBIAN_VERSION must be supplied by tools/version.sh}"
: "${DEBIAN_PARENT_IMAGE:?DEBIAN_PARENT_IMAGE must be supplied by tools/version.sh}"

output_dir=$(pwd)

# get_stats <package>
get_stats() {
    package=$1
    info "searching package cache for ${package}"

    if ! metadata=$(apt-cache show "${package}" --no-all-versions 2>/dev/null); then
        fail "package is unavailable from the approved parent's repositories: ${package}"
    fi
    package_version=$(printf '%s\n' "${metadata}" | sed -n 's/^Version: //p' | sed -n '1p')
    package_sha=$(printf '%s\n' "${metadata}" | sed -n 's/^SHA256: //p' | sed -n '1p')
    package_path=$(printf '%s\n' "${metadata}" | sed -n 's/^Filename: //p' | sed -n '1p')
    package_filename=${package_path##*/}

    if [ -z "${package_version}" ] || [ -z "${package_sha}" ] || [ -z "${package_filename}" ]; then
        fail "failed to get complete package information for ${package}"
    fi

    success "found ${package} ${package_version}"
}

# download <package> <version> <filename>
download() {
    info "downloading $1 $2"
    apt-get download -qq "$1=$2"

    if [ ! -f "$3" ]; then
        fail "download did not produce expected file: $3"
    fi

    success "downloaded $3"
}

# check_hash <filename> <expected SHA-256>
check_hash() {
    actual_hash=$(sha256sum "$1")
    actual_hash=${actual_hash%% *}

    info "expected SHA-256: $2"
    info "package SHA-256:  ${actual_hash}"

    if [ "${actual_hash}" != "$2" ]; then
        fail "SHA-256 verification failed for $1"
    fi

    success "verified $1"
}

# extract_deb <filename> <output directory>
extract_deb() {
    deb_file=$1
    package_dir=$2
    extraction_dir=$(mktemp -d)

    info "extracting ${deb_file}"
    (
        cd "${extraction_dir}"
        ar x "${deb_file}"
    )

    set -- "${extraction_dir}"/data.tar.*
    if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
        fail "could not identify one data archive in ${deb_file}"
    fi

    case "$1" in
        *.tar.zst)
            tar -C "${package_dir}" --use-compress-program=unzstd -xf "$1"
            ;;
        *.tar.gz|*.tar.xz|*.tar.bz2)
            tar -C "${package_dir}" -xf "$1"
            ;;
        *)
            fail "unsupported Debian data archive: $1"
            ;;
    esac

    success "extracted ${deb_file}"
}

# collect_packages <package> ...
collect_packages() {
    download_dir=$(mktemp -d)
    package_dir=$(mktemp -d)

    chown _apt:root "${download_dir}"
    cd "${download_dir}"

    for package in "$@"; do
        get_stats "${package}"
        download "${package}" "${package_version}" "${package_filename}"
        check_hash "${package_filename}" "${package_sha}"
        extract_deb "${download_dir}/${package_filename}" "${package_dir}"
    done

    cd "${output_dir}"
    info "packaging Debian runtime files"
    tar -C "${package_dir}" -czf packages.tgz .
    success "created packages.tgz"
}

# Debian 13 uses a merged-/usr filesystem. Preserve the compatibility links
# expected by dynamically linked applications without shipping a package manager.
make_symlinks() {
    link_dir=$(mktemp -d)

    for link in lib lib64 bin sbin; do
        ln -s "/usr/${link}" "${link_dir}/${link}"
    done

    tar -C "${link_dir}" -czf "${output_dir}/symlinks.tgz" lib lib64 bin sbin
    success "created symlinks.tgz"
}

# Copy only the identity and trust files that the production Ubuntu pattern
# obtains from its approved parent image.
make_identity() {
    identity_dir=$(mktemp -d)

    command -v useradd >/dev/null 2>&1 \
        || fail "approved Debian parent does not provide useradd"
    grep -q '^nogroup:' /etc/group \
        || fail "approved Debian parent does not provide the nogroup group"
    grep -q '^user:' /etc/passwd \
        && fail "approved Debian parent already defines a user account named user"

    useradd --no-create-home --uid 10000 --gid nogroup --shell /usr/sbin/nologin user
    sed -i 's|^\(root:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*:[^:]*$|\1:/usr/sbin/nologin|' /etc/passwd

    grep -q '^user:[^:]*:10000:' /etc/passwd \
        || fail "failed to create the unprivileged UID 10000 account"
    grep -q '^root:[^:]*:0:0:[^:]*::/usr/sbin/nologin$' /etc/passwd \
        || fail "failed to disable the root login shell"

    mkdir -p "${identity_dir}/etc/ssl/certs"
    cp /etc/passwd /etc/shadow /etc/group "${identity_dir}/etc/"

    if [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then
        fail "approved Debian parent does not provide the CA certificate bundle"
    fi
    cp /etc/ssl/certs/ca-certificates.crt "${identity_dir}/etc/ssl/certs/"

    if [ ! -e /etc/os-release ] || [ ! -f /etc/debian_version ]; then
        fail "approved Debian parent does not provide Debian release identity files"
    fi
    cp -L /etc/os-release "${identity_dir}/etc/os-release"
    cp /etc/debian_version "${identity_dir}/etc/debian_version"

    tar -C "${identity_dir}" -czf "${output_dir}/identity.tgz" .
    success "created identity.tgz"
}

expected_major=${DEBIAN_VERSION%%.*}
actual_release=$(sed -n '1p' /etc/debian_version)
actual_major=${actual_release%%.*}

if [ "${actual_major}" != "${expected_major}" ]; then
    fail "approved parent ${DEBIAN_PARENT_IMAGE} reports Debian ${actual_release}, expected major ${expected_major}"
fi

info "using approved parent: ${DEBIAN_PARENT_IMAGE}"
info "approved parent reports Debian: ${actual_release}"
info "installing package-extraction dependencies"
apt-get -qq update
apt-get -qq install -y --no-install-recommends binutils xz-utils zstd

# Match the established Ubuntu distroless package set: basic network service
# definitions plus the distribution's C library and runtime loader.
collect_packages netbase libc6
make_symlinks
make_identity
