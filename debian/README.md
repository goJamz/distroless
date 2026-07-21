# Distroless Base Container - Debian

The Debian distroless image is a minimal Debian GNU/Linux runtime intended for
production applications. The initial release is Debian 13 (Trixie), assembled
from packages obtained through the cDSO approved Debian parent image.

## Contents

The image contains only:

- The Debian GNU C Library and runtime loader
- GCC's low-level runtime support library required by Debian's GNU C Library
- Basic network service definitions from `netbase`
- The CA certificate bundle from the approved Debian parent
- Essential user and group files
- An unprivileged `user` account with UID 10000
- The `/tmp` and `/home/user` directories supplied by the cDSO build pipeline

It does not contain a shell, package manager, or common diagnostic utilities.
Applications must supply their executable and any additional runtime
dependencies.

## Usage

```Dockerfile
FROM registry.cdso.army.mil/cdso/containers/approved-base/distroless:debian-13.0

COPY --chown=user:nogroup --chmod=550 app .
ENTRYPOINT ["./app"]
```

The default working directory is `/home/user`, and the application runs as
`user`. Because the image has no shell and no default command, derivative
images must configure an exec-form `ENTRYPOINT` for their application.

## Releasing a Debian version

Release tags use the form `debian-X.Y`. The small version helper removes the
`debian-` prefix so the package job and Docker build use the approved Debian
parent tag `vX.Y`.

For Debian 13:

```bash
git tag -a debian-13.0 -m "13.0" main
git push origin debian-13.0
```

The cDSO review-and-delivery pipeline starts automatically and publishes:

```text
registry.cdso.army.mil/cdso/containers/approved-base/distroless:debian-13.0
```

A future `debian-14.0` release tag will select the approved parent
`debian:v14.0` without a source change. The corresponding approved parent must
exist before the release pipeline runs.

## Validation boundary

Shell syntax, tag resolution, YAML structure, and Dockerfile structure can be
checked locally. The approved Debian parent, cDSO registry, review component,
image build, Dockerfile lint job, SBOM, and vulnerability scans are available
only inside IL5 and must be validated there after copying the contribution.
