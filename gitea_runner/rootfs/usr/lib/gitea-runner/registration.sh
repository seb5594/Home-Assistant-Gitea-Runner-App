#!/usr/bin/env bash
# shellcheck shell=bash
# Registers the runner with Gitea and remembers under which settings it did.
#
# The registration lives in $RUNNER_FILE (written by the runner itself, it holds the runner's own
# token). $FINGERPRINT_FILE remembers the settings it was made for; when the address, scope, name
# or registration token changes, the runner registers again.

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
  if [[ "$GR_REGISTRATION_MODE" == "registration_token" ]]; then
    token_hash="$(printf '%s' "$GR_REGISTRATION_TOKEN" | sha256sum | cut -d' ' -f1)"
  fi
  jq -nc --arg instance "$GR_GITEA_URL" --arg scope "$GR_SCOPE" --arg target "$GR_TARGET" \
    --arg name "$GR_NAME" --arg token "$token_hash" \
    '{instance: $instance, scope: $scope, target: $target, name: $name, token: $token}'
}

# request_registration_token
# Asks Gitea for a registration token with the access token. Sets REGISTRATION_TOKEN on success;
# otherwise REGISTRATION_ERROR_STATE and REGISTRATION_ERROR (a message JSON).
request_registration_token() {
  local base path method
  base="$(registration_api_base "$GR_SCOPE" "$GR_TARGET")"
  REGISTRATION_TOKEN=""
  REGISTRATION_ERROR_STATE="failed"
  REGISTRATION_ERROR=""

  # Gitea creates the token with POST; older versions hand it out with GET on a shorter path.
  for method in POST GET; do
    for path in "${base}/actions/runners/registration-token" "${base}/runners/registration-token"; do
      HTTP_METHOD="$method" http_get "${GR_GITEA_URL}/api/v1/${path}" "$GR_GITEA_INSECURE" "$GR_CA_CERT" "$GR_ACCESS_TOKEN"
      if [[ "$HTTP_CODE" == "200" ]] && REGISTRATION_TOKEN="$(jq -er '.token' <<<"$HTTP_BODY" 2>/dev/null)"; then
        return 0
      fi
      [[ "$HTTP_CODE" =~ ^(404|405|501)$ ]] || break 2
    done
  done

  case "$HTTP_CODE" in
    000)
      REGISTRATION_ERROR_STATE="waiting"
      REGISTRATION_ERROR="$(message no_answer "Gitea does not answer: $(describe_failure)." reason "$(failure_reason)" rc "$CURL_RC")"
      ;;
    401)
      REGISTRATION_ERROR_STATE="rejected"
      REGISTRATION_ERROR="$(message access_token_rejected "Gitea does not accept the access token.")"
      ;;
    403)
      REGISTRATION_ERROR_STATE="rejected"
      REGISTRATION_ERROR="$(message access_token_scope "The access token may not create runner registration tokens for this scope (administrator rights or the matching write scope are needed).")"
      ;;
    404 | 405)
      REGISTRATION_ERROR_STATE="rejected"
      REGISTRATION_ERROR="$(message scope_not_found "Gitea has nothing to register runners for this scope: check registration.target, and that Actions are enabled in Gitea." scope "$GR_SCOPE" target "$GR_TARGET")"
      ;;
    *)
      REGISTRATION_ERROR="$(message registration_http "Gitea answered the request for a registration token with HTTP ${HTTP_CODE}." http "$HTTP_CODE")"
      ;;
  esac
  return 1
}

# runner_is_gone
# True when an access token is set and Gitea does not know the registered runner any more.
runner_is_gone() {
  [[ "$GR_REGISTRATION_MODE" == "access_token" ]] || return 1
  [[ "$(probe_remote_runner "$GR_GITEA_URL" "$GR_GITEA_INSECURE" "$GR_CA_CERT" "$GR_ACCESS_TOKEN" \
    "$GR_SCOPE" "$GR_TARGET" "$(jq -r '.id // ""' "$RUNNER_FILE" 2>/dev/null)" | jq -r '.code')" == "runner_gone" ]]
}

# forget_registration <scope> <target>
# Removes the old registration. With an access token the runner is also deleted in Gitea.
forget_registration() {
  local old_scope="$1" old_target="$2" id
  id="$(jq -r '.id // ""' "$RUNNER_FILE" 2>/dev/null)" || id=""
  if [[ -n "$GR_ACCESS_TOKEN" && -n "$id" ]]; then
    HTTP_METHOD=DELETE http_get "${GR_GITEA_URL}/api/v1/$(registration_api_base "$old_scope" "$old_target")/actions/runners/${id}" \
      "$GR_GITEA_INSECURE" "$GR_CA_CERT" "$GR_ACCESS_TOKEN"
    if [[ "$HTTP_CODE" == "204" ]]; then
      log_info "Removed the old runner registration from Gitea."
    else
      log_warning "The old runner could not be removed from Gitea (HTTP ${HTTP_CODE}); remove it there by hand."
    fi
  fi
  rm -f -- "$RUNNER_FILE"
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
  local stored="" current delay=10 waiting_state

  current="$(registration_fingerprint)"
  if [[ -s "$RUNNER_FILE" ]]; then
    stored="$(cat "$FINGERPRINT_FILE" 2>/dev/null)" || stored=""
    if [[ -z "$stored" ]]; then
      registration_fingerprint >"$FINGERPRINT_FILE"
      stored="$current"
    fi
    if [[ "$(jq -S . <<<"$stored")" == "$(jq -S . <<<"$current")" ]]; then
      if runner_is_gone; then
        log_info "Gitea does not know the runner any more: registering it again."
        forget_registration "$GR_SCOPE" "$GR_TARGET"
      else
        set_registration_state registered "$(message registered "The runner is registered.")"
        return 0
      fi
    elif [[ "$GR_REGISTRATION_MODE" == "none" ]]; then
      log_warning "The settings changed, but there is no token to register again; keeping the existing registration."
      set_registration_state registered "$(message registered "The runner is registered.")"
      return 0
    else
      log_info "The registration settings changed: registering the runner again."
      forget_registration "$(jq -r '.scope' <<<"$stored")" "$(jq -r '.target' <<<"$stored")"
    fi
  fi

  if [[ "$GR_REGISTRATION_MODE" == "none" ]]; then
    set_registration_state needs_credentials "$(message needs_credentials "Enter a registration token (or an access token) in the app configuration.")"
    return 1
  fi

  while true; do
    if [[ "$GR_REGISTRATION_MODE" == "registration_token" ]]; then
      run_registration "$GR_REGISTRATION_TOKEN" && return 0
      waiting_state="$(jq -r '.state' "$REGISTRATION_STATE_FILE")"
    elif request_registration_token; then
      run_registration "$REGISTRATION_TOKEN" && return 0
      waiting_state="$(jq -r '.state' "$REGISTRATION_STATE_FILE")"
    else
      waiting_state="$REGISTRATION_ERROR_STATE"
      set_registration_state "$waiting_state" "$REGISTRATION_ERROR"
      log_warning "$(jq -r '.text' <<<"$REGISTRATION_ERROR")"
    fi
    [[ "$waiting_state" == "waiting" ]] || return 1
    log_info "Waiting ${delay} seconds for Gitea before the next try."
    nap "$delay"
    delay=$((delay < 60 ? delay + 10 : 60))
  done
}
