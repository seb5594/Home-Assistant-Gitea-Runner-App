#!/usr/bin/env bash
# shellcheck shell=bash
# Connection checks that turn "it does not work" into a sentence the user can act on.
# Every probe prints one JSON object and never fails.
#
# A problem is reported as English text (for the log) and as a code with arguments, which the
# app page translates into the language of the browser: {"error": "...", "code": "...", "args": {}}
# (see message and set_error in common.sh).

# http_get <url> <insecure> <ca-file> [token]
# Sets HTTP_CODE (000 when nothing answered), HTTP_BODY and CURL_RC. HTTP_METHOD (default GET)
# picks the method. The token travels on stdin so that it never appears in the process list.
http_get() {
  local url="$1" insecure="$2" ca_file="$3" token="${4:-}"
  local body_file args=(-sS --max-time 6 -K - -X "${HTTP_METHOD:-GET}")
  body_file="$(mktemp)"
  args+=(-o "$body_file" -w '%{http_code}')
  if [[ "$insecure" == "true" ]]; then
    args+=(-k)
  fi
  if [[ -n "$ca_file" ]]; then
    args+=(--cacert "$ca_file")
  fi
  # A failing curl must not end the script (bashio runs services with errexit): keep its exit code.
  CURL_RC=0
  HTTP_CODE="$(
    if [[ -n "$token" ]]; then
      printf 'header = "Authorization: token %s"\n' "$token"
    fi | curl "${args[@]}" "$url" 2>/dev/null
  )" || CURL_RC=$?
  HTTP_BODY="$(cat "$body_file")"
  rm -f "$body_file"
  HTTP_CODE="${HTTP_CODE:-000}"
}

# failure_reason
# A code for the last http_get that got no usable answer: host_unknown, refused, timeout, tls
# or failed (then CURL_RC says more).
failure_reason() {
  case "$CURL_RC" in
    6) printf 'host_unknown' ;;
    7) printf 'refused' ;;
    28) printf 'timeout' ;;
    35 | 51 | 58 | 60 | 77 | 83) printf 'tls' ;;
    *) printf 'failed' ;;
  esac
}

# describe_failure
# A short English reason for the last http_get that got no usable answer.
describe_failure() {
  case "$(failure_reason)" in
    host_unknown) printf 'the host name is unknown' ;;
    refused) printf 'the connection was refused (is the app started?)' ;;
    timeout) printf 'the request timed out' ;;
    tls) printf 'the TLS certificate is not trusted (see the advanced options)' ;;
    *) printf 'the connection failed (curl error %s)' "$CURL_RC" ;;
  esac
}

# probe_gitea <url> <insecure> <ca-file> <token>
# {"reachable", "version", "error", "code", "args",
#  "token": {"state": none|ok|rejected|error, "login", "error", "code", "args"}}
probe_gitea() {
  local url="$1" insecure="$2" ca_file="$3" token="$4"
  local version="" reachable=false error="" gitea_error="" gitea_msg='{}'
  local token_state="none" login="" token_error="" token_msg='{}'

  http_get "${url}/api/v1/version" "$insecure" "$ca_file" "$token"
  if [[ "$HTTP_CODE" == "200" ]] && version="$(jq -er '.version' <<<"$HTTP_BODY" 2>/dev/null)"; then
    reachable=true
  elif [[ "$CURL_RC" != "0" || "$HTTP_CODE" == "000" ]]; then
    set_error gitea no_answer "Gitea does not answer: $(describe_failure)." reason "$(failure_reason)" rc "$CURL_RC"
    error="$gitea_error"
  elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
    reachable=true
    set_error gitea login_required "Gitea requires a login for everything; the access token decides what the app may check."
    error="$gitea_error"
  else
    set_error gitea not_gitea "${url} answers, but it does not look like Gitea (HTTP ${HTTP_CODE}). Check the address." url "$url" http "$HTTP_CODE"
    error="$gitea_error"
  fi

  if [[ -n "$token" && "$reachable" == "true" ]]; then
    http_get "${url}/api/v1/user" "$insecure" "$ca_file" "$token"
    case "$HTTP_CODE" in
      200)
        token_state="ok"
        login="$(jq -r '.login // ""' <<<"$HTTP_BODY" 2>/dev/null)" || login=""
        ;;
      401 | 403)
        token_state="rejected"
        set_error token token_rejected "Gitea does not accept this access token."
        ;;
      *)
        token_state="error"
        set_error token token_http "The token could not be checked (HTTP ${HTTP_CODE})." http "$HTTP_CODE"
        ;;
    esac
  elif [[ -n "$token" ]]; then
    token_state="error"
    set_error token token_unreachable "The token could not be checked because Gitea is not reachable."
  fi

  jq -nc --argjson reachable "$reachable" --arg version "$version" --arg error "$error" \
    --argjson gitea_msg "$gitea_msg" --arg state "$token_state" --arg login "$login" \
    --arg token_error "$token_error" --argjson token_msg "$token_msg" '
    {reachable: $reachable, version: $version, error: $error,
     code: ($gitea_msg.code // ""), args: ($gitea_msg.args // {}),
     token: {state: $state, login: $login, error: $token_error,
             code: ($token_msg.code // ""), args: ($token_msg.args // {})}}'
}

# probe_runner
# What the runner reports about itself on its metrics address:
# {"running", "ready", "version", "capacity", "jobs_running", "jobs_succeeded", "jobs_failed"}
probe_runner() {
  local running=false ready=false metrics=""
  if curl -fs --max-time 3 -o /dev/null "http://${METRICS_ADDRESS}/healthz"; then
    running=true
    metrics="$(curl -fs --max-time 3 "http://${METRICS_ADDRESS}/metrics" 2>/dev/null)" || metrics=""
    if curl -fs --max-time 3 -o /dev/null "http://${METRICS_ADDRESS}/readyz"; then
      ready=true
    fi
  fi
  # gitea_runner_job_total{status="success"} 3
  awk -v running="$running" -v ready="$ready" '
    function number(line) { n = split(line, parts, " "); return parts[n] + 0 }
    /^gitea_runner_info\{/ { match($0, /version="[^"]*"/); version = substr($0, RSTART + 9, RLENGTH - 10) }
    /^gitea_runner_capacity / { capacity = number($0) }
    /^gitea_runner_job_running / { active = number($0) }
    /^gitea_runner_job_total\{status="success"\}/ { succeeded += number($0) }
    /^gitea_runner_job_total\{status="(failure|cancelled|skipped)"\}/ { failed += number($0) }
    END {
      printf "{\"running\":%s,\"ready\":%s,\"version\":\"%s\",\"capacity\":%d,\"jobs_running\":%d,\"jobs_succeeded\":%d,\"jobs_failed\":%d}\n",
        running, ready, version, capacity, active, succeeded, failed
    }' <<<"$metrics"
}

# registration_api_base
# The part of the Gitea API path that belongs to the scope the runner is registered for.
registration_api_base() {
  case "$1" in
    instance) printf 'admin' ;;
    user) printf 'user' ;;
    organization) printf 'orgs/%s' "$2" ;;
    repository) printf 'repos/%s' "$2" ;;
  esac
}

# probe_remote_runner <url> <insecure> <ca-file> <token> <scope> <target> <runner-id>
# What Gitea itself says about this runner (needs an access token with the right scope):
# {"state": online|offline|unknown, "busy", "labels", "error", "code", "args"}
probe_remote_runner() {
  local url="$1" insecure="$2" ca_file="$3" token="$4" scope="$5" target="$6" id="$7"
  local state="unknown" busy=false labels='[]' remote_error="" remote_msg='{}' base

  if [[ -z "$token" || -z "$id" ]]; then
    jq -nc '{state: "unknown", busy: false, labels: [], error: "", code: "", args: {}}'
    return 0
  fi
  base="$(registration_api_base "$scope" "$target")"
  http_get "${url}/api/v1/${base}/actions/runners/${id}" "$insecure" "$ca_file" "$token"
  case "$HTTP_CODE" in
    200)
      state="$(jq -r '.status // "unknown"' <<<"$HTTP_BODY" 2>/dev/null)" || state="unknown"
      busy="$(jq -r '.busy // false' <<<"$HTTP_BODY" 2>/dev/null)" || busy=false
      labels="$(jq -c '[.labels[]?.name]' <<<"$HTTP_BODY" 2>/dev/null)" || labels='[]'
      ;;
    401 | 403) set_error remote token_scope "Gitea does not let this access token look at runners (it needs the scope for runners, or administrator rights)." ;;
    404) set_error remote runner_gone "Gitea does not know this runner (any more)." ;;
    000) set_error remote no_answer "Gitea does not answer: $(describe_failure)." reason "$(failure_reason)" rc "$CURL_RC" ;;
    *) set_error remote runner_http "Gitea answered the runner check with HTTP ${HTTP_CODE}." http "$HTTP_CODE" ;;
  esac
  jq -nc --arg state "$state" --argjson busy "$busy" --argjson labels "$labels" \
    --arg error "$remote_error" --argjson msg "$remote_msg" '
    {state: $state, busy: $busy, labels: $labels, error: $error,
     code: ($msg.code // ""), args: ($msg.args // {})}'
}
