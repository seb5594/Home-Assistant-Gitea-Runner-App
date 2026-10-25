ARG BUILD_FROM=ghcr.io/home-assistant/base:3.24-2026.10.0

# The official image only holds the static Go binary on a bare Alpine. The binary is copied
# into the Home Assistant base image, which brings bashio and s6-overlay.
# renovate: datasource=docker depName=docker.io/gitea/runner
ARG GITEA_RUNNER_VERSION=5.2.2
FROM docker.io/gitea/runner:${GITEA_RUNNER_VERSION} AS gitea-runner

FROM ${BUILD_FROM}

# Jobs run inside this app, on what the image holds: the runner clones actions with git, and most
# actions (actions/checkout, ...) are JavaScript, so they need node. openssh-client is for deploying
# to other machines. busybox-extras brings the httpd of the app page, which Alpine's busybox lacks.
RUN apk add --no-cache \
    # renovate: datasource=repology depName=alpine_3_24/git
    git=2.54.0-r0 \
    # renovate: datasource=repology depName=alpine_3_24/nodejs
    nodejs=24.22.1-r0 \
    # renovate: datasource=repology depName=alpine_3_24/openssh-client-default
    openssh-client-default=10.3_p1-r1 \
    # renovate: datasource=repology depName=alpine_3_24/busybox-extras
    busybox-extras=1.37.0-r31 \
    # renovate: datasource=repology depName=alpine_3_24/curl
    curl=8.22.0-r0 \
    # renovate: datasource=repology depName=alpine_3_24/jq
    jq=1.8.2-r0

COPY --from=gitea-runner /usr/local/bin/gitea-runner /usr/local/bin/gitea-runner
RUN gitea-runner --version

COPY rootfs/ /
COPY licenses/ /usr/share/licenses/gitea-runner/
COPY LICENSE THIRD_PARTY_NOTICES.md /usr/share/licenses/gitea-runner/

# Git does not keep the executable bit when files are uploaded through the GitHub API.
RUN chmod a+x /usr/lib/gitea-runner/*.sh /usr/share/gitea-runner/web/cgi-bin/* \
    && find /etc/s6-overlay/s6-rc.d -type f \( -name run -o -name finish \) -exec chmod a+x {} + \
    && mkdir -p /run/gitea-runner \
    && ln -s /run/gitea-runner/status.json /usr/share/gitea-runner/web/status.json

ARG BUILD_VERSION=1.0.0-dev4
ARG BUILD_ARCH=amd64
RUN echo "${BUILD_VERSION}" >/etc/gitea-runner/version
LABEL io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.source="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App"

HEALTHCHECK --interval=5m --timeout=10s --start-period=1m --retries=3 \
    CMD ["/usr/lib/gitea-runner/healthcheck.sh"]
