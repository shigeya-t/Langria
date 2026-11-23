# The web app as a container image: the static files served by BusyBox httpd
# on an empty (scratch) base, about 1 MB in all. Published to ghcr.io by
# .github/workflows/container.yml.
#
#   docker build --build-arg COMMIT=$(git rev-parse --short HEAD) -t langria .
#   docker run --rm -p 8080:8080 langria   # open http://localhost:8080
ARG BUSYBOX=busybox:1.38.0-musl

# The files are the same on every platform, so they are put together once on the build machine.
FROM --platform=$BUILDPLATFORM ${BUSYBOX} AS site
ARG COMMIT=
WORKDIR /www
COPY index.html styles.css app.js ./
COPY extension/lib/i18n.js extension/lib/vault.js extension/lib/languages.js extension/lib/
COPY extension/icons/icon.svg extension/icons/
# version.js is optional (the settings panel shows the commit hash when it is there).
# BusyBox's built-in MIME types have no charset and no SVG, so they are set in httpd.conf.
RUN if [ -n "$COMMIT" ]; then printf "globalThis.LANGRIA_COMMIT = '%s';\n" "$COMMIT" > extension/lib/version.js; fi \
 && printf '%s\n' '.html:text/html;charset=utf-8' '.css:text/css;charset=utf-8' '.js:text/javascript;charset=utf-8' '.svg:image/svg+xml' > /httpd.conf \
 && chmod -R a+rX /www /httpd.conf

# The musl build of BusyBox is statically linked, so it runs without any libraries.
FROM ${BUSYBOX} AS busybox

FROM scratch
COPY --from=busybox /bin/busybox /bin/busybox
COPY --from=site /httpd.conf /etc/httpd.conf
COPY --from=site /www /www
USER 65534:65534
EXPOSE 8080
HEALTHCHECK CMD ["/bin/busybox", "wget", "-q", "--spider", "http://127.0.0.1:8080/"]
# httpd runs as PID 1 and has no SIGTERM handler, so the kernel would ignore SIGTERM
# and `docker stop` would wait 10 seconds. It holds no state, so stop it at once.
STOPSIGNAL SIGKILL
ENTRYPOINT ["/bin/busybox", "httpd", "-f", "-p", "8080", "-h", "/www", "-c", "/etc/httpd.conf"]
