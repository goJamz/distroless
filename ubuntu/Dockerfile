ARG REGISTRY=registry.cdso.army.mil/cdso/containers

FROM ${REGISTRY}/approved-base/ubuntu:24.04 AS build

# Add a non-root user
RUN useradd -m -u 10000 -g nogroup -s /usr/sbin/nologin user

# Set root workdir to / & remove login
RUN sed -i 's|/root:/bin.*|:/usr/sbin/nologin|' /etc/passwd

# configure the final container
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
