#!/bin/sh

TOOLS_DIR=$(dirname -- "$0")
. ${TOOLS_DIR}/cdso_tools.sh

alias pkg="apk -q --no-cache"

# download <pkg name> <pkg dir>
download() {
    pkg fetch --recursive -o $2 $1
    if test $? -ne 0; then
        fail "failed downloading package"
    fi

    for apkpath in $(find $2 -type f -name "*.apk"); do
        info "validating $apkpath"
        apkfile=$(basename "$apkpath")
        pkg verify "$apkpath"
        if test $? -ne 0; then
            fail "failed verification for $apkfile"
        else
            success "verified $apkfile"
        fi

        cd "$2" && \
        tar xzf "$apkfile" && \
        cd - >/dev/null
        if test $? -ne 0; then
            fail "failed to extract $apkfile"
        fi

        rm "$apkpath"
        if test $? -ne 0; then
            fail "failed to clean up $apkfile"
        fi
    done
}

# repackage <pkg dir> <pkg file>
repackage() {
    info "packaging all files"
    tar -C $1 -czf $2 .
    if test $? -ne 0; then
        fail "error repacking"
    fi
}

# collect_packages <name> ...
collect_packages() {
    pkgdir=$(mktemp -d)
   
    for name in "$@"; do
        download "$name" "$pkgdir"
    done

    repackage "$pkgdir" packages.tgz
}

pkg update
if test $? -ne 0; then
    fail "could not update package index"
fi

if [ "${CI_COMMIT_TAG:-alpine-static}" = "alpine-static" ]; then
    collect_packages alpine-release alpine-baselayout-data
else
    collect_packages musl alpine-release alpine-baselayout-data
fi
