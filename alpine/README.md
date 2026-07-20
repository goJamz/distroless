# Distroless Base Container - Alpine

The `alpine` distroless containers provide minimal base systems intended for
use by production-ready applications. There are two variants: the static
variant contains the bare minimum for a viable Docker container, and the
numeric variants contain the musl C library[^1] (i.e. musl libc 1.2.4 in
`alpine-3.18`) in addition. They are intended to be used in the same way as
Google's distroless[^2] static and base containers.

## Contents

The image does **not** contain most of the binaries and files you would expect
with a normal system. It only contains:

- DoD TLS certificates
- An unprivileged user
- The `/tmp` and `/home/user` directories
- Essential system files
- The musl C library (except for `alpine-static`)

## Usage

Ensure you use the correct tag for your application. The current supported
versions are:

| Tag | Distroless Image Size | Corresponding Alpine Image | Alpine Image Size
| :--: | :--: | :--: | :--:
| distroless:alpine-static | 177.96 KiB | alpine (any) | N/A
| distroless:alpine-3.17 | 978.33 KiB | alpine:3.17 | 4.51 MiB
| distroless:alpine-3.18 | 978.25 KiB | alpine:3.18 | 4.55 MiB

Instances of a `distroless` container must include the compiled application and
all of its dependencies. **There is no shell**, which means that the container
will fail to run without the ENTRYPOINT pointing to the application. An example
Dockerfile using this image is shown below:

```docker
ARG REGISTRY=registry.levelup.cce.af.mil/cdso/containers

FROM $REGISTRY/base-registry/distroless:alpine-3.18
COPY --chown=user:user --chmod=550 app .
ENTRYPOINT ["./app"]
```

**Note:** the Docker `WORKDIR` of the container is set to `/home/user` by
default, and the main process will run as `user`.

## Maintenance

Releases are based on LTS versions of each distribution. To release a new
container, create a tag with the name `[distribution]-[version]` and message
`[version]`.

Image sizes are the compressed size used for storage in GitLab repositories;
distroless images are stored [here](https://code.levelup.cce.af.mil/cdso/containers/base-registry/container_registry/789) and referenced Alpine images are stored [here](https://code.levelup.cce.af.mil/cdso/containers/base-registry/container_registry/218).

## References

[^1]: https://musl.libc.org/
[^2]: https://github.com/GoogleContainerTools/distroless
