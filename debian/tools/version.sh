#!/bin/sh

tag=${CI_COMMIT_TAG:-${DEFAULT_DEBIAN_RELEASE_TAG:-debian-13.0}}
output=${1:-debian.env}

case "${tag}" in
    debian-*)
        version=${tag#debian-}
        ;;
    *)
        echo "release tag must use the form debian-X.Y: ${tag}" >&2
        exit 1
        ;;
esac

case "${version}" in
    *[!0-9.]*|''|.*|*.|*.*.*)
        echo "release tag must use the form debian-X.Y: ${tag}" >&2
        exit 1
        ;;
esac

case "${version}" in
    *.*) ;;
    *)
        echo "release tag must use the form debian-X.Y: ${tag}" >&2
        exit 1
        ;;
esac

printf 'DEBIAN_VERSION=%s\n' "${version}" > "${output}"
printf 'DEBIAN_PARENT_IMAGE=registry.cdso.army.mil/cdso/containers/approved-base/debian:v%s\n' \
    "${version}" >> "${output}"
