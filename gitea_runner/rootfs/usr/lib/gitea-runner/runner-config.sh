#!/usr/bin/env bash
# shellcheck shell=bash
# Writes the configuration file of the runner from the resolved settings.
# Only paths and switches go in; the registration (with its token) is kept in $RUNNER_FILE.

RUNNER_CONFIG="${RUNNER_CONFIG:-${RUNTIME_DIR}/config.yaml}"
CACHE_DIR="${CACHE_DIR:-${DATA_DIR}/cache}"
WORK_DIR="${WORK_DIR:-${DATA_DIR}/work}"
RUNNER_HOME="${RUNNER_HOME:-${DATA_DIR}/home}"

write_runner_config() {
  local label level="info"
  if [[ "$GR_DEBUG" == "true" ]]; then
    level="debug"
  fi

  mkdir -p "$(dirname "$RUNNER_CONFIG")" "$CACHE_DIR" "$WORK_DIR" "$RUNNER_HOME"
  {
    echo "# Generated at every start from the app options; changes here are lost."
    echo "log:"
    echo "  level: ${level}"
    echo "runner:"
    echo "  file: $(yaml_string "$RUNNER_FILE")"
    echo "  capacity: ${GR_CAPACITY}"
    echo "  insecure: ${GR_IGNORE_TLS}"
    echo "  labels:"
    for label in "${GR_LABELS[@]}"; do
      echo "    - $(yaml_string "${label}:host")"
    done
    echo "cache:"
    echo "  dir: $(yaml_string "$CACHE_DIR")"
    echo "host:"
    echo "  workdir_parent: $(yaml_string "$WORK_DIR")"
    echo "metrics:"
    echo "  enabled: true"
    echo "  addr: $(yaml_string "$METRICS_ADDRESS")"
  } >"${RUNNER_CONFIG}.new"
  mv "${RUNNER_CONFIG}.new" "$RUNNER_CONFIG"
}
