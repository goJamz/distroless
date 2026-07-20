ARG REGISTRY=registry.cdso.army.mil

FROM $REGISTRY/cdso/containers/approved-base/alpine:3.22 AS build

# add a non-root user, fix root's workdir, remove root login
RUN adduser -S -u 10000 -G nobody -s /sbin/nologin user && \
    sed -i 's./root:/bin*./:/sbin/nologin.g' /etc/passwd

# configure the final container
FROM scratch
ADD tmp_home.tar.gz packages.tgz /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/
COPY --from=build /etc/shadow /etc/
COPY --from=build /etc/group /etc/
WORKDIR /home/user
USER user
