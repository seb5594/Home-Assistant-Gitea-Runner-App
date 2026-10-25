#!/usr/bin/env bash
# shellcheck shell=bash
# Builds $RUNTIME_DIR/status.json, the file the app page shows.
#
# It combines the resolved settings (resolved.json, written at start) with the state of the
# registration and fresh checks. The page asks for a new run now and then, see cgi-bin/recheck.

# refresh_status
# Runs the checks and replaces status.json atomically. Prints the new status.
refresh_status() {
  local resolved="$RUNTIME_DIR/resolved.json"
  local url insecure scratch gitea_check='null' registration='{"state":"starting"}'

  [[ -f "$resolved" ]] || { log_error "No resolved settings yet."; return 1; }
  url="$(jq -r '.gitea.url' "$resolved")"
  insecure="$(jq -r '.gitea.insecure' "$resolved")"

  if [[ -n "$url" ]]; then
    gitea_check="$(probe_gitea "$url" "$insecure")"
  fi
  if [[ -f "$REGISTRATION_STATE_FILE" ]]; then
    registration="$(cat "$REGISTRATION_STATE_FILE")"
  fi

  scratch="$(mktemp "$RUNTIME_DIR/status.XXXXXX")"
  jq --argjson gitea "$gitea_check" --argjson registration "$registration" \
    --argjson runner "$(probe_runner)" --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    .checked_at = $checked_at
    | .gitea += ($gitea // {})
    | .registration += $registration
    | .runner += $runner
  ' "$resolved" >"$scratch"
  chmod 644 "$scratch"
  mv "$scratch" "$RUNTIME_DIR/status.json"
  cat "$RUNTIME_DIR/status.json"
}

# log_status
# One summary of the status for the app log.
log_status() {
  local status="$RUNTIME_DIR/status.json" version

  if [[ "$(jq -r '.gitea.reachable // false' "$status")" == "true" ]]; then
    version="$(jq -r '.gitea.version' "$status")"
    log_info "Gitea${version:+ ${version}} is reachable at $(jq -r '.gitea.url' "$status")."
  else
    log_warning "Gitea at $(jq -r '.gitea.url' "$status"): $(jq -r '.gitea.error' "$status")"
  fi
  if [[ "$(jq -r '.runner.ready' "$status")" == "true" ]]; then
    log_info "The runner is up and waits for jobs (capacity $(jq -r '.runner.capacity' "$status"))."
  fi
}
