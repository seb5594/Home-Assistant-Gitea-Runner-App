#!/usr/bin/env bash
# shellcheck shell=bash
# Registers the runner with Gitea and remembers under which settings it did.
#
# The registration lives in $RUNNER_FILE (written by the runner itself, it holds the runner's own
# token). $FINGERPRINT_FILE remembers the settings it was made for; when the address, name or
# registration token changes, the runner registers again.

FINGERPRINT_FILE="${FINGERPRINT_FILE:-${DATA_DIR}/registration.json}"
REGISTRATION_STATE_FILE="${REGISTRATION_STATE_FILE:-${RUNTIME_DIR}/registration.json}"

# set_registration_state <state> <message JSON>
# state: waiting | registered | needs_credentials | rejected | failed
# Tells the app page where the registration stands.
set_registration_state() {
  mkdir -p "$RUNTIME_DIR"
  jq -c --arg state "$1" '. + {state: $state}' <<<"$2" >"${REGISTRATION_STATE_FILE}.new"
  mv "${REGISTRATION_STATE_FILE}.new" "$REGISTRATION_STATE_FILE"
}

# registration_fingerprint
# The settings the registration depends on. The registration token only counts as a hash, so that
# entering a fresh one registers again, while a token that stays does not.
registration_fingerprint() {
  local token_hash=""
  if [[ -n "$GR_REGISTRATION_TOKEN" ]]; then
    token_hash="$(printf '%s' "$GR_REGISTRATION_TOKEN" | sha256sum | cut -d' ' -f1)"
  fi
  jq -nc --arg instance "$GR_GITEA_URL" --arg name "$GR_NAME" --arg token "$token_hash" \
    '{instance: $instance, name: $name, token: $token}'
}

# run_registration
# One try with the runner binary. Sets the registration state; returns 0 only when registered.
run_registration() {
  local token="$1" token_file output rc=0
  token_file="$(mktemp)"
  printf '%s' "$token" >"$token_file"
  output="$(gitea-runner -c "$RUNNER_CONFIG" register --no-interactive \
    --instance "$GR_GITEA_URL" --token-file "$token_file" --name "$GR_NAME" 2>&1)" || rc=$?
  rm -f -- "$token_file"

  if ((rc == 0)) && [[ -s "$RUNNER_FILE" ]]; then
    registration_fingerprint >"$FINGERPRINT_FILE"
    log_info "Registered the runner '${GR_NAME}' with Gitea."
    set_registration_state registered "$(message registered "The runner is registered.")"
    return 0
  fi

  case "$output" in
    *"registration token not found"*)
      set_registration_state rejected "$(message registration_token_rejected "Gitea does not accept this registration token. Copy a fresh one from the runners page of Gitea.")"
      ;;
    *"cannot ping the Gitea"*)
      set_registration_state waiting "$(message waiting "Gitea does not answer yet.")"
      ;;
    *)
      set_registration_state failed "$(message register_failed "The runner could not be registered: $(tail -n 1 <<<"$output")" detail "$(tail -n 1 <<<"$output")")"
      ;;
  esac
  log_warning "Registration failed: $(tail -n 1 <<<"$output")"
  return 1
}

# ensure_registered
# Makes sure the runner has a registration that fits the settings. Waits while Gitea is not
# reachable. Returns 0 when registered; 1 when the settings need a change (see the app page).
ensure_registered() {
  local stored="" current delay=10

  current="$(registration_fingerprint)"
  if [[ -s "$RUNNER_FILE" ]]; then
    stored="$(cat "$FINGERPRINT_FILE" 2>/dev/null)" || stored=""
    if [[ -z "$stored" ]]; then
      printf '%s\n' "$current" >"$FINGERPRINT_FILE"
      stored="$current"
    fi
    if [[ "$(jq -S . <<<"$stored")" == "$(jq -S . <<<"$current")" ]]; then
      set_registration_state registered "$(message registered "The runner is registered.")"
      return 0
    fi
    if [[ -z "$GR_REGISTRATION_TOKEN" ]]; then
      # The usual case: the token was removed after the registration, it is not needed any more.
      set_registration_state registered "$(message registered "The runner is registered.")"
      return 0
    fi
    log_info "The address, name or registration token changed: registering the runner again."
    rm -f -- "$RUNNER_FILE"
  fi

  if [[ -z "$GR_REGISTRATION_TOKEN" ]]; then
    set_registration_state needs_credentials "$(message needs_credentials "Enter a registration token in the app configuration.")"
    return 1
  fi

  while true; do
    run_registration "$GR_REGISTRATION_TOKEN" && return 0
    [[ "$(jq -r '.state' "$REGISTRATION_STATE_FILE")" == "waiting" ]] || return 1
    log_info "Waiting ${delay} seconds for Gitea before the next try."
    nap "$delay"
    delay=$((delay < 60 ? delay + 10 : 60))
  done
}
