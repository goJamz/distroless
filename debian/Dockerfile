ARG REGISTRY=registry.cdso.army.mil/cdso/containers

FROM ${REGISTRY}/approved-base/debian:v13.0 AS build

# Add the non-root account used by applications in the final image.
RUN useradd --create-home --uid 10000 --gid nogroup --shell /usr/sbin/nologin user \
    && sed -i 's|/root:/bin.*|:/usr/sbin/nologin|' /etc/passwd

FROM scratch

ADD tmp_home.tar.gz /
ADD packages.tgz /
ADD symlinks.tgz /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/
COPY --from=build /etc/shadow /etc/
COPY --from=build /etc/group /etc/

WORKDIR /home/user
USER user
