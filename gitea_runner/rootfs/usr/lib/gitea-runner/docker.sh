#!/usr/bin/env bash
# shellcheck shell=bash
# Talks to the Docker engine of Home Assistant OS, where the jobs in containers run.
#
# The Supervisor mounts the socket into an app that has `docker_api: true` and protection mode
# switched off. The tests point DOCKER_URL at a mock instead (DOCKER_SOCKET empty).

DOCKER_SOCKET="${DOCKER_SOCKET-/run/docker.sock}"
DOCKER_URL="${DOCKER_URL:-http://localhost}"
# The network the Supervisor puts all apps on; jobs that join it reach Gitea, Home Assistant
# and the other apps by name.
HOME_ASSISTANT_NETWORK="hassio"

# docker_get <path>
# Body of a Docker API response; fails on HTTP errors.
docker_get() {
  local args=(-fsS --max-time 5)
  if [[ -n "$DOCKER_SOCKET" ]]; then
    args+=(--unix-socket "$DOCKER_SOCKET")
  fi
  curl "${args[@]}" "${DOCKER_URL}$1"
}

# probe_docker
# {"available", "version", "error", "code", "args"}
probe_docker() {
  local available=false version="" error="" docker_error="" docker_msg='{}' reply

  if [[ -n "$DOCKER_SOCKET" && ! -S "$DOCKER_SOCKET" ]]; then
    set_error docker docker_no_socket "The Docker socket is not available. Switch off 'Protection mode' on the Info tab of this app and restart it."
    error="$docker_error"
  elif reply="$(docker_get /version 2>/dev/null)"; then
    available=true
    version="$(jq -r '.Version // ""' <<<"$reply" 2>/dev/null)" || version=""
  else
    set_error docker docker_no_answer "The Docker engine does not answer on its socket."
    error="$docker_error"
  fi

  jq -nc --argjson available "$available" --arg version "$version" --arg error "$error" \
    --argjson msg "$docker_msg" '
    {available: $available, version: $version, error: $error,
     code: ($msg.code // ""), args: ($msg.args // {})}'
}

# docker_network_exists <name>
docker_network_exists() {
  docker_get "/networks/$1" >/dev/null 2>&1
}

# app_container_address <slug>
# The IP address of an app's container on the Home Assistant network; fails when unknown.
app_container_address() {
  docker_get "/containers/addon_$1/json" 2>/dev/null \
    | jq -er --arg network "$HOME_ASSISTANT_NETWORK" '.NetworkSettings.Networks[$network].IPAddress | select(. != null and . != "")'
}
