ARG BUILD_FROM=ghcr.io/seb5594/home-assistant-base:3.24-2026.11.0

# The official image only holds the static Go binary on a bare Alpine. The binary is copied
# into the Home Assistant base image, which brings bashio and s6-overlay.
# renovate: datasource=docker depName=docker.io/gitea/runner
ARG GITEA_RUNNER_VERSION=6.0.1
FROM docker.io/gitea/runner:${GITEA_RUNNER_VERSION} AS gitea-runner

FROM ${BUILD_FROM}

# Jobs run inside this app, on what the image holds: the runner clones actions with git, and most
# actions (actions/checkout, ...) are JavaScript, so they need node. openssh-client is for deploying
# to other machines. util-linux-misc brings taskset, which busybox lacks and which keeps jobs on a
# few CPU cores. busybox-extras brings the httpd of the app page, which Alpine's busybox lacks.

RUN apk add --no-cache nodejs \
    git \
    openssh-client-default \
    util-linux-misc \
    busybox-extras \
    curl \
    jq

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

ARG BUILD_VERSION=6.0.1
RUN echo "${BUILD_VERSION}" >/etc/gitea-runner/version
LABEL io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    org.opencontainers.image.title="Home Assistant App: Gitea Runner" \
    org.opencontainers.image.version="${BUILD_VERSION}" \
    org.opencontainers.image.source="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App"

HEALTHCHECK --interval=5m --timeout=10s --start-period=1m --retries=3 \
    CMD ["/usr/lib/gitea-runner/healthcheck.sh"]
