#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # the GR_* variables are read by the scripts that source this file
# Turns the app options into the values the runner is configured with.
#
# resolve_settings fills the GR_* variables and writes the non-secret part to
# $RUNTIME_DIR/resolved.json for the app page. Anything wrong with the options is collected
# in GR_PROBLEMS (blocks the start) or GR_NOTICES (the runner starts anyway) instead of
# aborting, so that the app page can explain it.

SSL_DIR="${SSL_DIR:-/ssl}"
DATA_DIR="${DATA_DIR:-/data}"
RUNNER_FILE="${RUNNER_FILE:-${DATA_DIR}/.runner}"
METRICS_ADDRESS="127.0.0.1:9101"

DEFAULT_RUNNER_NAME="home-assistant"
# The label of jobs that run directly in this app instead of in a container.
HOST_LABEL="home-assistant"
JOB_IMAGE_REPOSITORY="docker.gitea.com/runner-images"
HOME_ASSISTANT_API_URL="http://supervisor/core/api"
# What the folders of this app hold, for jobs in host mode: path|description
HOST_FOLDERS=(
  "/homeassistant|config"
  "/share|share"
  "/media|media"
  "/backup|backup"
  "/ssl|ssl"
)

GR_PROBLEMS=()
GR_PROBLEM_DETAILS=()
GR_NOTICES=()
GR_NOTICE_DETAILS=()

# add_problem <code> <english text> [name value ...]
# A problem that keeps the runner from starting. Collected as text (log and fallback) and as
# code with arguments (the app page translates it into the language of the browser).
add_problem() {
  local code="$1" text="$2"
  shift 2
  GR_PROBLEMS+=("$text")
  GR_PROBLEM_DETAILS+=("$(message "$code" "$text" "$@")")
  log_error "$text"
}

# add_notice <code> <english text> [name value ...]
# Something worth knowing; the runner starts anyway.
add_notice() {
  local code="$1" text="$2"
  shift 2
  GR_NOTICES+=("$text")
  GR_NOTICE_DETAILS+=("$(message "$code" "$text" "$@")")
  log_warning "$text"
}

resolve_ca_certificate() {
  local name
  GR_CA_CERT=""
  name="$(option advanced.ca_certificate)"
  [[ -z "$name" ]] && return 0
  if [[ "$name" == *..* || ! -f "${SSL_DIR}/${name}" ]]; then
    add_problem ca_missing "Certificate file '${name}' was not found in the /ssl folder." name "$name"
    return 0
  fi
  GR_CA_CERT="${SSL_DIR}/${name}"
}

# The Gitea address the runner talks to: the configured one, or the Gitea app.
resolve_gitea() {
  local configured scheme
  GR_GITEA_URL=""
  GR_GITEA_SOURCE=""
  GR_GITEA_WEB_URL=""
  GR_APP_JSON=""
  GR_GITEA_INSECURE="$GR_IGNORE_TLS"

  configured="$(trim_url "$(option gitea_url)")"
  configured="${configured%/api/v1}"
  if [[ -n "$configured" ]]; then
    if is_http_url "$configured"; then
      GR_GITEA_URL="$configured"
      GR_GITEA_SOURCE="url"
      GR_GITEA_WEB_URL="$configured"
    else
      add_problem bad_gitea_url "gitea_url '${configured}' is not a web address. Use the form http://homeassistant.local:3000." url "$configured"
    fi
  elif GR_APP_JSON="$(find_gitea_app)"; then
    scheme="http"
    if [[ "$(jq -r '.ssl' <<<"$GR_APP_JSON")" == "true" ]]; then
      scheme="https"
    fi
    GR_GITEA_URL="${scheme}://$(jq -r '.hostname' <<<"$GR_APP_JSON"):$(jq -r '.port' <<<"$GR_APP_JSON")"
    GR_GITEA_SOURCE="app:$(jq -r '.slug' <<<"$GR_APP_JSON")"
    GR_GITEA_WEB_URL="$(trim_url "$(jq -r '.root_url' <<<"$GR_APP_JSON")")"
    if [[ "$scheme" == "https" && -z "$GR_CA_CERT" ]]; then
      # The certificate belongs to the public domain, not to the app's internal host name.
      GR_GITEA_INSECURE=true
      log_info "The Gitea app uses SSL; its certificate is not checked for the connection inside Home Assistant."
    fi
  else
    add_problem no_gitea "No Gitea was found. Install the Gitea app, or enter the address of your Gitea in 'gitea_url'."
  fi
}

# Where the runner is registered (the whole instance, one user, one organization or one repository)
# and how it gets the registration token.
resolve_registration() {
  GR_SCOPE="$(option registration.scope instance)"
  GR_TARGET="$(option registration.target)"
  GR_TARGET="${GR_TARGET//[[:space:]]/}"
  GR_REGISTRATION_TOKEN="$(option registration.registration_token)"
  GR_ACCESS_TOKEN="$(option registration.access_token)"

  case "$GR_SCOPE" in
    organization)
      if [[ ! "$GR_TARGET" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        add_problem bad_target "registration.target must be the name of the organization for this scope." scope "$GR_SCOPE" target "$GR_TARGET"
      fi
      ;;
    repository)
      if [[ ! "$GR_TARGET" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
        add_problem bad_target "registration.target must look like owner/repository for this scope." scope "$GR_SCOPE" target "$GR_TARGET"
      fi
      ;;
    *) GR_TARGET="" ;;
  esac

  if [[ -n "$GR_REGISTRATION_TOKEN" ]]; then
    GR_REGISTRATION_MODE="registration_token"
  elif [[ -n "$GR_ACCESS_TOKEN" ]]; then
    GR_REGISTRATION_MODE="access_token"
  else
    GR_REGISTRATION_MODE="none"
  fi

  GR_RUNNERS_PAGE=""
  if [[ -n "$GR_GITEA_WEB_URL" ]]; then
    case "$GR_SCOPE" in
      instance) GR_RUNNERS_PAGE="${GR_GITEA_WEB_URL}/-/admin/actions/runners" ;;
      user) GR_RUNNERS_PAGE="${GR_GITEA_WEB_URL}/user/settings/actions/runners" ;;
      organization) GR_RUNNERS_PAGE="${GR_GITEA_WEB_URL}/org/${GR_TARGET}/settings/actions/runners" ;;
      repository) GR_RUNNERS_PAGE="${GR_GITEA_WEB_URL}/${GR_TARGET}/settings/actions/runners" ;;
    esac
  fi
}

resolve_runner_name() {
  GR_NAME="$(option runner_name "$DEFAULT_RUNNER_NAME")"
  if [[ ! "$GR_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._\ -]{0,62}$ ]]; then
    add_problem bad_runner_name "runner_name '${GR_NAME}' may only hold letters, digits, blanks, dots, dashes and underscores." name "$GR_NAME"
  fi
}

# add_label <name> <host|docker> <schema> [image]
# Adds a label once; jobs in containers are left out when there is no Docker engine.
add_label() {
  local name="$1" kind="$2" schema="$3" image="${4:-}" skipped=false
  if [[ " ${GR_LABEL_NAMES} " == *" ${name} "* ]]; then
    return 0
  fi
  GR_LABEL_NAMES+="${name} "
  if [[ "$kind" == "docker" && "$GR_DOCKER_OK" != "true" ]]; then
    skipped=true
  else
    GR_LABEL_LINES+=("${name}:${schema}")
  fi
  GR_LABEL_DETAILS+=("$(jq -nc --arg name "$name" --arg kind "$kind" --arg image "$image" --argjson skipped "$skipped" \
    '{name: $name, kind: $kind, image: $image, skipped: $skipped}')")
}

# The labels decide which jobs the runner takes, and how it runs them.
resolve_labels() {
  local suffix="" preset entry name schema skipped_docker=0

  GR_LABEL_NAMES=""
  GR_LABEL_LINES=()
  GR_LABEL_DETAILS=()
  case "$GR_JOB_IMAGE" in
    slim) suffix="-slim" ;;
    full) suffix="-full" ;;
  esac

  while read -r preset; do
    [[ -n "$preset" ]] || continue
    add_label "$preset" docker "docker://${JOB_IMAGE_REPOSITORY}:${preset}${suffix}" "${JOB_IMAGE_REPOSITORY}:${preset}${suffix}"
  done < <(option_lines labels)

  if [[ "$GR_HOST_ENABLED" == "true" ]]; then
    add_label "$HOST_LABEL" host host
  fi

  while read -r entry; do
    entry="${entry//[[:space:]]/}"
    [[ -n "$entry" ]] || continue
    if [[ ! "$entry" =~ ^([A-Za-z0-9][A-Za-z0-9._-]*)(:host|:docker://[^[:space:]]+)?$ ]]; then
      add_problem bad_label "The label '${entry}' is not valid. Use name, name:host or name:docker://image." label "$entry"
      continue
    fi
    name="${BASH_REMATCH[1]}"
    schema="${BASH_REMATCH[2]#:}"
    if [[ -z "$schema" || "$schema" == "host" ]]; then
      if [[ "$GR_HOST_ENABLED" == "true" ]]; then
        add_label "$name" host host
      else
        add_notice host_label_ignored "The label '${name}' runs jobs inside this app and is ignored while 'host_jobs' is switched off." label "$name"
      fi
    else
      add_label "$name" docker "$schema" "${schema#docker://}"
    fi
  done < <(option_lines advanced.extra_labels)

  GR_DOCKER_LABEL_COUNT="$(jq -s '[.[] | select(.kind == "docker")] | length' <<<"$(printf '%s\n' "${GR_LABEL_DETAILS[@]}")")"
  skipped_docker="$(jq -s '[.[] | select(.kind == "docker" and .skipped)] | length' <<<"$(printf '%s\n' "${GR_LABEL_DETAILS[@]}")")"
  if ((skipped_docker > 0)); then
    add_notice docker_unavailable "The Docker engine is not available, so ${skipped_docker} label(s) for jobs in containers are left out. Switch off 'Protection mode' of this app and restart it." count "$skipped_docker"
  fi
  if ((${#GR_LABEL_LINES[@]} == 0)); then
    add_problem no_labels "There is nothing the runner could run: enable 'host_jobs', or give it Docker access and choose labels."
  fi
}

# Jobs in containers join the network of the apps, so they reach Gitea, Home Assistant and the
# other apps by name. If Gitea announces itself under a name that only the apps' own network
# knows (http://homeassistant.local:3000), the jobs get that name mapped to the Gitea app.
resolve_job_network() {
  local root_url host port address
  GR_NETWORK=""
  GR_ADD_HOST=""
  ((GR_DOCKER_LABEL_COUNT > 0)) || return 0
  [[ "$GR_DOCKER_OK" == "true" ]] || return 0
  [[ "$(option advanced.home_assistant_network true)" == "true" ]] || return 0

  if ! docker_network_exists "$HOME_ASSISTANT_NETWORK"; then
    add_notice network_missing "The Docker network '${HOME_ASSISTANT_NETWORK}' does not exist; jobs run on a network of their own." network "$HOME_ASSISTANT_NETWORK"
    return 0
  fi
  GR_NETWORK="$HOME_ASSISTANT_NETWORK"

  [[ -n "$GR_APP_JSON" ]] || return 0
  root_url="$(jq -r '.root_url' <<<"$GR_APP_JSON")"
  if [[ "$root_url" =~ ^https?://([^/:]+):([0-9]+)/?$ ]]; then
    host="${BASH_REMATCH[1]}"
    port="${BASH_REMATCH[2]}"
    if [[ ! "$host" =~ ^[0-9.]+$ && "$port" == "$(jq -r '.port' <<<"$GR_APP_JSON")" ]] \
      && address="$(app_container_address "$(jq -r '.slug' <<<"$GR_APP_JSON")")"; then
      GR_ADD_HOST="${host}:${address}"
    fi
  fi
}

write_resolved() {
  local folders='[]' entry
  for entry in "${HOST_FOLDERS[@]}"; do
    folders="$(jq -c --arg path "${entry%%|*}" --arg name "${entry##*|}" '. + [{path: $path, name: $name}]' <<<"$folders")"
  done
  mkdir -p "$RUNTIME_DIR"
  jq -n \
    --arg hostname "$GR_APP_HOSTNAME" --arg version "$GR_APP_VERSION" \
    --arg url "$GR_GITEA_URL" --argjson insecure "$GR_GITEA_INSECURE" --arg source "$GR_GITEA_SOURCE" --arg web_url "$GR_GITEA_WEB_URL" \
    --arg runners_page "$GR_RUNNERS_PAGE" \
    --arg mode "$GR_REGISTRATION_MODE" --arg scope "$GR_SCOPE" --arg target "$GR_TARGET" --arg name "$GR_NAME" \
    --argjson capacity "$GR_CAPACITY" --arg job_image "$GR_JOB_IMAGE" \
    --argjson labels "$(json_list "${GR_LABEL_DETAILS[@]}")" \
    --argjson docker_in_jobs "$GR_DOCKER_IN_JOBS" --argjson privileged "$GR_PRIVILEGED" \
    --arg network "$GR_NETWORK" --arg add_host "$GR_ADD_HOST" \
    --argjson host_enabled "$GR_HOST_ENABLED" --argjson ha_api "$GR_HA_API" --argjson folders "$folders" \
    --argjson companions "$GR_COMPANIONS" --arg ca_cert "$GR_CA_CERT" \
    --argjson problems "$(printf '%s\n' "${GR_PROBLEMS[@]}" | jq -R . | jq -sc 'map(select(. != ""))')" \
    --argjson problem_details "$(json_list "${GR_PROBLEM_DETAILS[@]}")" \
    --argjson notices "$(printf '%s\n' "${GR_NOTICES[@]}" | jq -R . | jq -sc 'map(select(. != ""))')" \
    --argjson notice_details "$(json_list "${GR_NOTICE_DETAILS[@]}")" '
    {
      app: {hostname: $hostname, version: $version},
      gitea: {url: $url, insecure: $insecure, source: $source, web_url: $web_url, runners_page: $runners_page},
      registration: {mode: $mode, scope: $scope, target: $target, name: $name},
      runner: {capacity: $capacity},
      jobs: {
        image: $job_image, labels: $labels, network: $network, add_host: $add_host,
        docker_in_jobs: $docker_in_jobs, privileged: $privileged
      },
      host: {enabled: $host_enabled, home_assistant_api: $ha_api, folders: $folders},
      companions: $companions,
      ca_cert: $ca_cert,
      problems: $problems,
      problem_details: $problem_details,
      notices: $notices,
      notice_details: $notice_details
    }
  ' >"$RUNTIME_DIR/resolved.json"
}

resolve_settings() {
  local identity
  GR_PROBLEMS=()
  GR_PROBLEM_DETAILS=()
  GR_NOTICES=()
  GR_NOTICE_DETAILS=()
  GR_CAPACITY="$(option capacity 1)"
  GR_JOB_IMAGE="$(option job_image slim)"
  GR_HOST_ENABLED="$(option host_jobs.enabled false)"
  GR_HA_API="false"
  GR_DOCKER_IN_JOBS="$(option advanced.docker_in_jobs false)"
  GR_PRIVILEGED="$(option advanced.privileged_jobs false)"
  GR_TIMEOUT_MINUTES="$(option advanced.job_timeout_minutes 180)"
  GR_CACHE="$(option advanced.cache true)"
  GR_DEBUG="$(option advanced.debug_logging false)"
  GR_IGNORE_TLS="$(option advanced.ignore_certificate_errors false)"
  if [[ "$GR_HOST_ENABLED" == "true" ]]; then
    GR_HA_API="$(option host_jobs.home_assistant_api false)"
  fi

  identity="$(own_app_info)"
  GR_APP_HOSTNAME="$(jq -r '.hostname' <<<"$identity")"
  GR_APP_VERSION="$(jq -r '.version' <<<"$identity")"
  GR_COMPANIONS="$(find_companions)"
  GR_DOCKER="$(probe_docker)"
  GR_DOCKER_OK="$(jq -r '.available' <<<"$GR_DOCKER")"

  resolve_ca_certificate
  resolve_gitea
  resolve_registration
  resolve_runner_name
  resolve_labels
  resolve_job_network
  write_resolved
}
