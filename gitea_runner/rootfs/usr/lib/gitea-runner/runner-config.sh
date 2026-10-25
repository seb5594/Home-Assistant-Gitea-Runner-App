#!/usr/bin/env bash
# shellcheck shell=bash
# Writes the configuration file of the runner from the resolved settings.
# Only paths and switches go in; the registration (with its token) is kept in $RUNNER_FILE.

RUNNER_CONFIG="${RUNNER_CONFIG:-${RUNTIME_DIR}/config.yaml}"
CACHE_DIR="${CACHE_DIR:-${DATA_DIR}/cache}"
WORK_DIR="${WORK_DIR:-${DATA_DIR}/work}"
RUNNER_HOME="${RUNNER_HOME:-${DATA_DIR}/home}"

write_runner_config() {
  local line level="info" jobs_use_docker='"-"' options=""
  if [[ "$GR_DEBUG" == "true" ]]; then
    level="debug"
  fi
  # "-" keeps the Docker socket out of the jobs, an empty value mounts it.
  if [[ "$GR_DOCKER_IN_JOBS" == "true" ]]; then
    jobs_use_docker='""'
  fi
  if [[ -n "$GR_ADD_HOST" ]]; then
    options="--add-host=${GR_ADD_HOST}"
  fi

  mkdir -p "$(dirname "$RUNNER_CONFIG")" "$CACHE_DIR" "$WORK_DIR" "$RUNNER_HOME"
  {
    echo "# Generated at every start from the app options; changes here are lost."
    echo "log:"
    echo "  level: ${level}"
    echo "runner:"
    echo "  file: $(yaml_string "$RUNNER_FILE")"
    echo "  capacity: ${GR_CAPACITY}"
    echo "  timeout: ${GR_TIMEOUT_MINUTES}m"
    echo "  insecure: ${GR_GITEA_INSECURE}"
    if [[ "$GR_HA_API" == "true" ]]; then
      echo "  envs:"
      echo "    HA_API_URL: $(yaml_string "$HOME_ASSISTANT_API_URL")"
    fi
    echo "  labels:"
    for line in "${GR_LABEL_LINES[@]}"; do
      echo "    - $(yaml_string "$line")"
    done
    echo "cache:"
    echo "  enabled: ${GR_CACHE}"
    echo "  dir: $(yaml_string "$CACHE_DIR")"
    echo "container:"
    echo "  network: $(yaml_string "$GR_NETWORK")"
    echo "  privileged: ${GR_PRIVILEGED}"
    echo "  docker_host: ${jobs_use_docker}"
    echo "  options: $(yaml_string "$options")"
    echo "host:"
    echo "  workdir_parent: $(yaml_string "$WORK_DIR")"
    echo "metrics:"
    echo "  enabled: true"
    echo "  addr: $(yaml_string "$METRICS_ADDRESS")"
  } >"${RUNNER_CONFIG}.new"
  mv "${RUNNER_CONFIG}.new" "$RUNNER_CONFIG"
}
