#!/usr/bin/env bash
# shellcheck shell=bash
# Builds $RUNTIME_DIR/status.json, the file the app page shows.
#
# It combines the resolved settings (resolved.json, written at start) with the state of the
# registration and fresh checks. The page asks for a new run now and then, see cgi-bin/recheck.

# companion_states <companions JSON>
# The same list with the current state of every app.
companion_states() {
  local companions="$1" slug state result='[]'
  while read -r slug; do
    [[ -n "$slug" ]] || continue
    state="$(app_state "$slug")" || state="unknown"
    result="$(jq -c --arg slug "$slug" --arg state "$state" \
      '. + [$companions[] | select(.slug == $slug) | . + {state: $state}]' --argjson companions "$companions" <<<"$result")"
  done < <(jq -r '.[].slug' <<<"$companions")
  printf '%s\n' "$result"
}

# refresh_status
# Runs the checks and replaces status.json atomically. Prints the new status.
refresh_status() {
  local resolved="$RUNTIME_DIR/resolved.json"
  local url insecure ca_cert token scope target runner_id scratch
  local gitea_check='null' registration='{"state":"starting"}' remote

  [[ -f "$resolved" ]] || { log_error "No resolved settings yet."; return 1; }
  url="$(jq -r '.gitea.url' "$resolved")"
  insecure="$(jq -r '.gitea.insecure' "$resolved")"
  token="$(option registration.access_token)"
  ca_cert="$(jq -r '.ca_cert' "$resolved")"
  scope="$(jq -r '.registration.scope' "$resolved")"
  target="$(jq -r '.registration.target' "$resolved")"
  runner_id="$(jq -r '.id // ""' "$RUNNER_FILE" 2>/dev/null)" || runner_id=""

  if [[ -n "$url" ]]; then
    gitea_check="$(probe_gitea "$url" "$insecure" "$ca_cert" "$token")"
  fi
  if [[ -f "$REGISTRATION_STATE_FILE" ]]; then
    registration="$(cat "$REGISTRATION_STATE_FILE")"
  fi
  remote="$(probe_remote_runner "$url" "$insecure" "$ca_cert" "$token" "$scope" "$target" "$runner_id")"

  scratch="$(mktemp "$RUNTIME_DIR/status.XXXXXX")"
  jq --argjson gitea "$gitea_check" --argjson registration "$registration" \
    --argjson runner "$(probe_runner)" --argjson remote "$remote" --argjson docker "$(probe_docker)" \
    --argjson companions "$(companion_states "$(jq -c '.companions' "$resolved")")" \
    --arg runner_id "$runner_id" --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    .checked_at = $checked_at
    | .gitea += ($gitea // {})
    | .registration += $registration
    | .registration.runner_id = $runner_id
    | .runner += $runner
    | .runner.remote = $remote
    | .docker = $docker
    | .companions = $companions
  ' "$resolved" >"$scratch"
  chmod 644 "$scratch"
  mv "$scratch" "$RUNTIME_DIR/status.json"
  cat "$RUNTIME_DIR/status.json"
}

# log_status
# One summary of the status for the app log.
log_status() {
  local status="$RUNTIME_DIR/status.json"

  if [[ "$(jq -r '.gitea.reachable // false' "$status")" == "true" ]]; then
    log_info "Gitea $(jq -r '.gitea.version' "$status") at $(jq -r '.gitea.url' "$status") ($(jq -r '.gitea.source' "$status"))"
  elif [[ "$(jq -r '.gitea.url' "$status")" != "" ]]; then
    log_warning "Gitea at $(jq -r '.gitea.url' "$status"): $(jq -r '.gitea.error' "$status")"
  fi
  if [[ "$(jq -r '.runner.ready' "$status")" == "true" ]]; then
    log_info "The runner is up and waits for jobs (capacity $(jq -r '.runner.capacity' "$status"))."
  fi
  case "$(jq -r '.runner.remote.state' "$status")" in
    online) log_info "Gitea shows the runner as online." ;;
    offline) log_warning "Gitea shows the runner as offline." ;;
  esac
}
