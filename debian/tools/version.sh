#!/bin/sh

set -eu

TOOLS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${TOOLS_DIR}/cdso_tools.sh"

default_release_tag=${DEFAULT_DEBIAN_RELEASE_TAG:-debian-13.0}
release_tag=${CI_COMMIT_TAG:-${default_release_tag}}
output_file=${1:-debian.env}

case "${release_tag}" in
    debian-*)
        debian_version=${release_tag#debian-}
        ;;
    *)
        fail "release tag must use the form debian-X.Y; received: ${release_tag}"
        ;;
esac

major_version=${debian_version%%.*}
minor_version=${debian_version#*.}

if [ "${major_version}" = "${debian_version}" ]; then
    fail "release tag must include a major and minor version: ${release_tag}"
fi

case "${major_version}" in
    ''|*[!0-9]*)
        fail "release tag has an invalid major version: ${release_tag}"
        ;;
esac

case "${minor_version}" in
    ''|*[!0-9]*|*.*)
        fail "release tag has an invalid minor version: ${release_tag}"
        ;;
esac

parent_registry=${DEBIAN_PARENT_REGISTRY:-registry.cdso.army.mil}
parent_tag="v${debian_version}"
parent_image="${parent_registry}/cdso/containers/approved-base/debian:${parent_tag}"

{
    printf 'DEBIAN_RELEASE_TAG=%s\n' "${release_tag}"
    printf 'DEBIAN_VERSION=%s\n' "${debian_version}"
    printf 'DEBIAN_PARENT_TAG=%s\n' "${parent_tag}"
    printf 'DEBIAN_PARENT_IMAGE=%s\n' "${parent_image}"
} > "${output_file}"

info "release tag: ${release_tag}"
info "approved parent: ${parent_image}"
success "wrote resolved Debian version to ${output_file}"
