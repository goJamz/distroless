ARG REGISTRY=registry.cdso.army.mil/cdso/containers
ARG DEBIAN_VERSION=13.0

FROM ${REGISTRY}/approved-base/debian:v${DEBIAN_VERSION} AS build

# Add a non-root user
RUN useradd -m -u 10000 -g nogroup -s /usr/sbin/nologin user

# Remove root login
RUN sed -i 's|/root:/bin.*|:/usr/sbin/nologin|' /etc/passwd

# Configure the final container
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
