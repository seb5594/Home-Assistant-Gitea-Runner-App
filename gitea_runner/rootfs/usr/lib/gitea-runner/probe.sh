#!/usr/bin/env bash
# shellcheck shell=bash
# Connection checks that turn "it does not work" into a sentence the user can act on.
# Every probe prints one JSON object and never fails.
#
# A problem is reported as English text (for the log) and as a code with arguments, which the
# app page translates into the language of the browser: {"error": "...", "code": "...", "args": {}}
# (see message and set_error in common.sh).

# http_get <url> <insecure>
# Sets HTTP_CODE (000 when nothing answered), HTTP_BODY and CURL_RC.
http_get() {
  local url="$1" insecure="$2"
  local body_file args=(-sS --max-time 6)
  body_file="$(mktemp)"
  args+=(-o "$body_file" -w '%{http_code}')
  if [[ "$insecure" == "true" ]]; then
    args+=(-k)
  fi
  # A failing curl must not end the script (bashio runs services with errexit): keep its exit code.
  CURL_RC=0
  HTTP_CODE="$(curl "${args[@]}" "$url" 2>/dev/null)" || CURL_RC=$?
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

# probe_gitea <url> <insecure>
# {"reachable", "version", "error", "code", "args"}
probe_gitea() {
  local url="$1" insecure="$2"
  local version="" reachable=false error="" gitea_error="" gitea_msg='{}'

  http_get "${url}/api/v1/version" "$insecure"
  if [[ "$HTTP_CODE" == "200" ]] && version="$(jq -er '.version' <<<"$HTTP_BODY" 2>/dev/null)"; then
    reachable=true
  elif [[ "$CURL_RC" != "0" || "$HTTP_CODE" == "000" ]]; then
    set_error gitea no_answer "Gitea does not answer: $(describe_failure)." reason "$(failure_reason)" rc "$CURL_RC"
    error="$gitea_error"
  elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
    # Gitea may demand a sign-in even for its version; that proves it is there.
    reachable=true
  else
    set_error gitea not_gitea "${url} answers, but it does not look like Gitea (HTTP ${HTTP_CODE}). Check the address." url "$url" http "$HTTP_CODE"
    error="$gitea_error"
  fi

  jq -nc --argjson reachable "$reachable" --arg version "$version" --arg error "$error" --argjson msg "$gitea_msg" '
    {reachable: $reachable, version: $version, error: $error,
     code: ($msg.code // ""), args: ($msg.args // {})}'
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
