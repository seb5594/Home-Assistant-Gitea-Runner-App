#!/usr/bin/env bash
# shellcheck shell=bash
# Docker health check: the runner has to answer on its metrics address.
# The start script creates $RUNTIME_DIR/daemon once the runner is launched; without it the app
# is still starting, or idle because the configuration needs attention (see the app page).

[[ -f "${RUNTIME_DIR:-/run/gitea-runner}/daemon" ]] || exit 0
curl -fs --max-time 5 -o /dev/null "http://127.0.0.1:9101/healthz"
