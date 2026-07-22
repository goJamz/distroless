ARG REGISTRY=registry.cdso.army.mil/cdso/containers
ARG DEBIAN_VERSION

FROM ${REGISTRY}/approved-base/debian:v${DEBIAN_VERSION} AS build

# Select libgcc-s1's copyright provider from the active Debian release.
RUN mkdir -p /tmp/packages /distroless && \
    chmod 1777 /tmp/packages && \
    cd /tmp/packages && \
    apt-get -qq update && \
    gcc_base="$(readlink /usr/share/doc/libgcc-s1)" && \
    apt-get download -qq netbase libc6 libgcc-s1 "$gcc_base" && \
    for package in *.deb; do dpkg-deb --extract "$package" /distroless || exit 1; done && \
    find /distroless/usr/share/doc -type f ! -name copyright -delete && \
    rm -rf /distroless/usr/share/lintian && \
    test -e /distroless/usr/share/doc/libgcc-s1/copyright && \
    ln -s /usr/lib /distroless/lib && \
    ln -s /usr/lib64 /distroless/lib64 && \
    test -e /distroless/usr/lib64/ld-linux-x86-64.so.2

# Add a non-root user, remove root login, and stage runtime directories.
RUN useradd -m -u 10000 -g nogroup -s /usr/sbin/nologin user && \
    sed -i 's|/root:/bin.*|:/usr/sbin/nologin|' /etc/passwd && \
    mkdir -p /distroless/tmp /distroless/home/user && \
    chmod 1777 /distroless/tmp && \
    chown user:nogroup /distroless/home/user

FROM scratch

COPY --from=build /distroless/ /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/
COPY --from=build /etc/shadow /etc/
COPY --from=build /etc/group /etc/

WORKDIR /home/user
USER user
