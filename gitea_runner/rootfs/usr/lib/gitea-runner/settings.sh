#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # the GR_* variables are read by the scripts that source this file
# Turns the app options into the values the runner is configured with.
#
# resolve_settings fills the GR_* variables and writes the non-secret part to
# $RUNTIME_DIR/resolved.json for the app page. Anything wrong with the options is collected in
# GR_PROBLEMS instead of aborting, so that the app page can explain it.

DATA_DIR="${DATA_DIR:-/data}"
RUNNER_FILE="${RUNNER_FILE:-${DATA_DIR}/.runner}"
METRICS_ADDRESS="127.0.0.1:9101"

# The Gitea app by alexbelgium, as the other apps of Home Assistant reach it.
DEFAULT_GITEA_URL="http://db21ed7f-gitea:3000"
DEFAULT_RUNNER_NAME="home-assistant"

GR_PROBLEMS=()
GR_PROBLEM_DETAILS=()

# add_problem <code> <english text> [name value ...]
# Collects a problem as text (log and fallback) and as code with arguments (the app page
# translates it into the language of the browser).
add_problem() {
  local code="$1" text="$2"
  shift 2
  GR_PROBLEMS+=("$text")
  GR_PROBLEM_DETAILS+=("$(message "$code" "$text" "$@")")
  log_error "$text"
}

resolve_gitea() {
  local configured
  GR_GITEA_URL=""
  GR_GITEA_SOURCE=""

  configured="$(trim_url "$(option gitea_url)")"
  configured="${configured%/api/v1}"
  if [[ -z "$configured" || "$configured" == "$DEFAULT_GITEA_URL" ]]; then
    GR_GITEA_URL="$DEFAULT_GITEA_URL"
    GR_GITEA_SOURCE="default"
  elif is_http_url "$configured"; then
    GR_GITEA_URL="$configured"
    GR_GITEA_SOURCE="url"
  else
    add_problem bad_gitea_url "gitea_url '${configured}' is not a web address. Use the form http://db21ed7f-gitea:3000." url "$configured"
  fi
}

resolve_runner_name() {
  GR_NAME="$(option runner_name "$DEFAULT_RUNNER_NAME")"
  if [[ ! "$GR_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._\ -]{0,62}$ ]]; then
    add_problem bad_runner_name "runner_name '${GR_NAME}' may only hold letters, digits, blanks, dots, dashes and underscores." name "$GR_NAME"
  fi
}

# The labels are the names a workflow puts in "runs-on". Every one runs jobs inside this app.
resolve_labels() {
  local label
  GR_LABELS=()
  while read -r label; do
    label="${label//[[:space:]]/}"
    [[ -n "$label" ]] || continue
    if [[ ! "$label" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
      add_problem bad_label "The label '${label}' is not valid. Use letters, digits, dots, dashes and underscores." label "$label"
    elif [[ " ${GR_LABELS[*]:-} " != *" ${label} "* ]]; then
      GR_LABELS+=("$label")
    fi
  done < <(option_lines labels)
  if ((${#GR_LABELS[@]} == 0)); then
    add_problem no_labels "There is no label, so no workflow could use this runner. Add at least one, for example home-assistant."
  fi
}

# cpu_list <cores> [status file]
# The CPUs jobs may use: the last <cores> of the CPUs this app is allowed to use, so the first
# ones stay free for Home Assistant. Prints nothing when the jobs may use all of them.
cpu_list() {
  local wanted="$1" status="${2:-/proc/self/status}" allowed part low high cpu
  local cpus=()
  allowed="$(sed -n 's/^Cpus_allowed_list:[[:space:]]*//p' "$status")"
  for part in ${allowed//,/ }; do
    low="${part%-*}"
    high="${part#*-}"
    for ((cpu = low; cpu <= high; cpu++)); do
      cpus+=("$cpu")
    done
  done
  if ((wanted >= ${#cpus[@]})); then
    return 0
  fi
  local IFS=,
  printf '%s' "${cpus[*]: -wanted}"
}

write_resolved() {
  mkdir -p "$RUNTIME_DIR"
  jq -n \
    --arg hostname "$GR_APP_HOSTNAME" --arg version "$GR_APP_VERSION" \
    --arg url "$GR_GITEA_URL" --argjson insecure "$GR_IGNORE_TLS" --arg source "$GR_GITEA_SOURCE" \
    --arg name "$GR_NAME" --argjson has_token "$GR_HAS_TOKEN" \
    --argjson capacity "$GR_CAPACITY" --arg cpu_list "$GR_CPU_LIST" \
    --argjson labels "$(printf '%s\n' "${GR_LABELS[@]}" | jq -R . | jq -sc 'map(select(. != ""))')" \
    --argjson problems "$(printf '%s\n' "${GR_PROBLEMS[@]}" | jq -R . | jq -sc 'map(select(. != ""))')" \
    --argjson problem_details "$(printf '%s\n' "${GR_PROBLEM_DETAILS[@]}" | jq -sc 'map(select(. != null))')" '
    {
      app: {hostname: $hostname, version: $version},
      gitea: {url: $url, insecure: $insecure, source: $source},
      registration: {name: $name, has_token: $has_token},
      runner: {capacity: $capacity, labels: $labels, cpu_list: $cpu_list},
      problems: $problems,
      problem_details: $problem_details
    }
  ' >"$RUNTIME_DIR/resolved.json"
}

resolve_settings() {
  local identity
  GR_PROBLEMS=()
  GR_PROBLEM_DETAILS=()
  GR_REGISTRATION_TOKEN="$(option registration_token)"
  GR_HAS_TOKEN=false
  if [[ -n "$GR_REGISTRATION_TOKEN" ]]; then
    GR_HAS_TOKEN=true
  fi
  GR_CAPACITY="$(option capacity 1)"
  GR_CPU_LIST="$(cpu_list "$(option advanced.cpu_cores 1)")"
  GR_DEBUG="$(option advanced.debug_logging false)"
  GR_IGNORE_TLS="$(option advanced.ignore_certificate_errors false)"

  identity="$(own_app_info)"
  GR_APP_HOSTNAME="$(jq -r '.hostname' <<<"$identity")"
  GR_APP_VERSION="$(jq -r '.version' <<<"$identity")"

  resolve_gitea
  resolve_runner_name
  resolve_labels
  write_resolved
}
