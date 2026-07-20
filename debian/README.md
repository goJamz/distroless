# Distroless Base Container — Debian Trixie

The `debian-13` image is a minimal Debian 13 (Trixie) base for
production-ready applications. It is assembled from packages obtained through
the cDSO approved Debian 13 parent and contains no shell or package manager.

## Contents

The image contains only:

- The Debian GNU C Library and runtime loader
- Basic network service definitions from `netbase`
- The CA certificate bundle from the approved Debian parent
- Essential user and group files
- An unprivileged `user` account with UID 10000
- `/tmp` and `/home/user`

Applications must supply their executable and every additional runtime
dependency. Because the image has no shell and no default command, derivative
images must configure an exec-form entrypoint.

```Dockerfile
ARG REGISTRY=registry.cdso.army.mil/cdso/containers

FROM ${REGISTRY}/approved-base/distroless:debian-13
COPY --chown=user:nogroup --chmod=550 app .
ENTRYPOINT ["./app"]
```

The default working directory is `/home/user`, and the application runs as
`user`.

## Building and releasing

The build requires the cDSO approved parent
`registry.cdso.army.mil/cdso/containers/approved-base/debian:v13.0`. The pre-build
job downloads the current Trixie `libc6` and `netbase` packages and their
required dependencies, verifies each package against APT's SHA-256 metadata,
and extracts them. It retains a minimal dpkg package inventory for SBOM and
vulnerability-scanner visibility before assembling the files into a `scratch`
image.

Create the release from a Git tag named `debian-13`.
