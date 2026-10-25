#!/usr/bin/env bash
set -Eeuo pipefail
# bashio starts the services with the same strictness; a library that only works without it fails
# in Home Assistant, not here.
shopt -s inherit_errexit

# Runs inside the built image (release pipeline). A mocked Supervisor, Docker engine and Gitea
# answer the app's libraries; a stand-in for the registration plays the part of Gitea's runner
# service, while the real gitea-runner binary reads the generated configuration.
LIB_DIR="${LIB_DIR:-/usr/lib/gitea-runner}"
RECHECK="${RECHECK_CGI:-/usr/share/gitea-runner/web/cgi-bin/recheck}"
HEALTHCHECK="${HEALTHCHECK_SCRIPT:-${LIB_DIR}/healthcheck.sh}"
REAL_RUNNER="$(command -v gitea-runner)"
read -r -a HTTPD <<<"${HTTPD_COMMAND:-busybox-extras httpd}"

fixture=$(mktemp -d)
pids=()
cleanup() {
  if ((${#pids[@]} > 0)); then kill "${pids[@]}" 2>/dev/null || true; fi
  rm -rf -- "$fixture"
}
trap cleanup EXIT

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

expect_equal() { # expect_equal <what> <expected> <actual>
  [[ "$2" == "$3" ]] || fail "$1: expected '$2', got '$3'"
}

# serve <directory> <port> [config-file]: a static web server in the background.
serve() {
  "${HTTPD[@]}" -f -p "127.0.0.1:$2" -h "$1" ${3:+-c "$3"} >/dev/null 2>&1 &
  pids+=($!)
}

# wait_for <url>: until the server answers.
wait_for() {
  for _ in $(seq 1 50); do
    curl -fs -o /dev/null "$1" && return 0
    sleep 0.1
  done
  fail "$1 did not come up"
}

# ---- fixtures: Supervisor on 18080, Docker on 18090, Gitea on 3000 and 3001 ----------------

mkdir -p "$fixture"/supervisor/addons/{db21ed7f_gitea,4c7fee11_gitea_mcp_server,self} \
  "$fixture"/docker/{networks,containers/addon_db21ed7f_gitea} \
  "$fixture"/gitea/api/v1/admin/{actions/runners,runners} "$fixture"/gitea-old/api/v1/admin/runners \
  "$fixture"/metrics
cat >"$fixture/supervisor/addons/db21ed7f_gitea/info" <<'JSON'
{"result":"ok","data":{"name":"Gitea","hostname":"127.0.0.1","state":"started","version":"28.2.0","options":{"ssl":false,"ROOT_URL":"http://homeassistant.local:3000/"}}}
JSON
cat >"$fixture/supervisor/addons/4c7fee11_gitea_mcp_server/info" <<'JSON'
{"result":"ok","data":{"name":"Gitea MCP Server","hostname":"abc-gitea-mcp-server","state":"started","version":"1.0.0-dev8","options":{}}}
JSON
cat >"$fixture/supervisor/addons/self/info" <<'JSON'
{"result":"ok","data":{"hostname":"abc-gitea-runner","version":"1.0.0-dev1"}}
JSON
echo '{"Version":"29.1.0"}' >"$fixture/docker/version"
echo '{"Name":"hassio"}' >"$fixture/docker/networks/hassio"
echo '{"NetworkSettings":{"Networks":{"hassio":{"IPAddress":"172.30.33.5"}}}}' >"$fixture/docker/containers/addon_db21ed7f_gitea/json"
echo '{"version":"28.2.0"}' >"$fixture/gitea/api/v1/version"
echo '{"login":"tester"}' >"$fixture/gitea/api/v1/user"
# The server only knows GET for static files, which is how old Gitea versions hand out tokens.
echo '{"token":"fresh-token-from-api"}' >"$fixture/gitea/api/v1/admin/actions/runners/registration-token"
echo '{"version":"1.22.0"}' >"$fixture/gitea-old/api/v1/version"
echo '{"token":"fresh-token-from-old-api"}' >"$fixture/gitea-old/api/v1/admin/runners/registration-token"
printf 'ok\n' >"$fixture/metrics/healthz"
printf 'ok\n' >"$fixture/metrics/readyz"
cat >"$fixture/metrics/metrics" <<'METRICS'
# HELP gitea_runner_capacity Configured capacity.
gitea_runner_capacity 2
gitea_runner_info{name="home-assistant",version="v5.2.2"} 1
gitea_runner_job_running 1
gitea_runner_job_total{status="success"} 5
gitea_runner_job_total{status="failure"} 2
gitea_runner_job_total{status="cancelled"} 1
METRICS

serve "$fixture/supervisor" 18080
serve "$fixture/docker" 18090
serve "$fixture/gitea" 3000
serve "$fixture/gitea-old" 3001
serve "$fixture/metrics" 9101
wait_for http://127.0.0.1:18080/addons/self/info
wait_for http://127.0.0.1:18090/version
wait_for http://127.0.0.1:3000/api/v1/version
wait_for http://127.0.0.1:3001/api/v1/version
wait_for http://127.0.0.1:9101/healthz

# Stand-in for the registration against Gitea (the binary needs Gitea's runner service for it):
# the token decides how it ends. Everything else is the real binary, see the last tests.
mkdir -p "$fixture/bin"
cat >"$fixture/bin/gitea-runner" <<'SCRIPT'
#!/usr/bin/env bash
[[ "$1" == "-c" ]] || exit 64
config="$2"
shift 2
[[ "$1" == "register" ]] || exec "$REAL_GITEA_RUNNER" -c "$config" "$@"
shift
while (($#)); do
  case "$1" in
    --instance) instance="$2"; shift ;;
    --token-file) token="$(cat "$2")"; shift ;;
    --name) name="$2"; shift ;;
  esac
  shift
done
case "$token" in
  bad-token) echo 'level=error msg="poller: cannot register new runner" error="unknown: runner registration token not found"'; exit 1 ;;
  offline-token) echo 'Error: failed to register runner: cannot ping the Gitea instance server: unavailable: connection refused'; exit 1 ;;
  odd-token) echo 'something unexpected happened'; exit 1 ;;
esac
file="$(REAL_GITEA_RUNNER="$REAL_GITEA_RUNNER" "$REAL_GITEA_RUNNER" -c "$config" config runner-file)"
jq -n --arg name "$name" --arg address "$instance" --arg token "$token" \
  '{id: 7, uuid: "00000000-0000-0000-0000-000000000007", name: $name, token: "runner-secret", address: $address, registered_with: $token}' >"$file"
echo 'Runner registered successfully.'
SCRIPT
chmod +x "$fixture/bin/gitea-runner"
export REAL_GITEA_RUNNER="$REAL_RUNNER"
export PATH="$fixture/bin:$PATH"

export SUPERVISOR_URL=http://127.0.0.1:18080 SUPERVISOR_TOKEN=test
export RUNTIME_DIR="$fixture/run" SSL_DIR="$fixture/ssl" OPTIONS_FILE="$fixture/options.json" DATA_DIR="$fixture/data"
export DOCKER_SOCKET="" DOCKER_URL=http://127.0.0.1:18090
mkdir -p "$RUNTIME_DIR" "$SSL_DIR" "$DATA_DIR"

# options <json>: the app options as the Supervisor would store them.
options() {
  jq -n --argjson overrides "$1" '
    {gitea_url: "", runner_name: "", capacity: 1, job_image: "slim", labels: ["ubuntu-latest"],
     registration: {scope: "instance", target: "", registration_token: "", access_token: ""},
     host_jobs: {enabled: false, home_assistant_api: false},
     advanced: {extra_labels: [], home_assistant_network: true, docker_in_jobs: false,
                privileged_jobs: false, job_timeout_minutes: 180, cache: true,
                ca_certificate: "", ignore_certificate_errors: false, debug_logging: false}}
    * $overrides' >"$OPTIONS_FILE"
}

# The libraries log through these three functions; the test keeps quiet.
# shellcheck disable=SC2329  # called by the libraries
log_info() { :; }
# shellcheck disable=SC2329
log_warning() { :; }
# shellcheck disable=SC2329
log_error() { :; }

export LIB="$LIB_DIR"
# shellcheck source=/dev/null
source "$LIB_DIR/load.sh"
# Tests must not wait for real: the pause between two tries ends the loop instead.
# shellcheck disable=SC2329
nap() { exit 99; }

# settings <options-json>: resolves the options in the current shell.
settings() {
  options "$1"
  rm -f -- "$fixture"/run/{registration.json,resolved.json}
  resolve_settings
}

resolved() { jq -r "$1" "$RUNTIME_DIR/resolved.json"; }

# ---- settings -----------------------------------------------------------------------------------

settings '{"host_jobs": {"enabled": true}}'
expect_equal "Gitea app found" "http://127.0.0.1:3000" "$GR_GITEA_URL"
expect_equal "Gitea app is the source" "app:db21ed7f_gitea" "$GR_GITEA_SOURCE"
expect_equal "labels with Docker" "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest-slim home-assistant:host" "${GR_LABEL_LINES[*]}"
expect_equal "jobs join the app network" "hassio" "$GR_NETWORK"
expect_equal "mDNS name of Gitea maps to the Gitea app" "homeassistant.local:172.30.33.5" "$GR_ADD_HOST"
expect_equal "no problems" "0" "${#GR_PROBLEMS[@]}"
expect_equal "page link to the runners" "http://homeassistant.local:3000/-/admin/actions/runners" "$(resolved '.gitea.runners_page')"
expect_equal "companion apps are found" "mcp" "$(resolved '.companions[0].id')"
pass "defaults find Gitea, the labels, the network and the companion apps"

settings '{"job_image": "standard", "labels": ["ubuntu-24.04", "ubuntu-22.04"]}'
expect_equal "standard images" "ubuntu-24.04:docker://docker.gitea.com/runner-images:ubuntu-24.04 ubuntu-22.04:docker://docker.gitea.com/runner-images:ubuntu-22.04" "${GR_LABEL_LINES[*]}"
settings '{"job_image": "full", "labels": ["ubuntu-latest"]}'
expect_equal "full images" "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest-full" "${GR_LABEL_LINES[*]}"
pass "the image size picks the image tag"

settings '{"advanced": {"extra_labels": ["python:docker://python:3.13-slim", "arm", "bad label!", "ubuntu-latest:docker://x"]}}'
expect_equal "extra Docker label added, duplicate skipped" "2" "${#GR_LABEL_LINES[@]}"
expect_equal "invalid label is a problem" "bad_label" "$(resolved '.problem_details[0].code')"
expect_equal "host label without host_jobs is a notice" "host_label_ignored" "$(resolved '.notice_details[0].code')"
pass "extra labels are validated"

DOCKER_URL=http://127.0.0.1:9 settings '{"host_jobs": {"enabled": true}}'
expect_equal "only the host label without Docker" "home-assistant:host" "${GR_LABEL_LINES[*]}"
expect_equal "no network without Docker" "" "$GR_NETWORK"
expect_equal "notice about Docker" "docker_unavailable" "$(resolved '.notice_details[0].code')"
expect_equal "skipped label is listed" "true" "$(resolved '.jobs.labels[0].skipped')"
pass "without Docker only host jobs remain"

DOCKER_URL=http://127.0.0.1:9 settings '{}'
expect_equal "nothing to run is a problem" "no_labels" "$(resolved '.problem_details[0].code')"
pass "no usable label blocks the start"

settings '{"advanced": {"home_assistant_network": false}}'
expect_equal "network can be switched off" "" "$GR_NETWORK"
expect_equal "and so is the name mapping" "" "$GR_ADD_HOST"
pass "joining the app network is optional"

settings '{"registration": {"scope": "organization", "target": "bad/name"}}'
expect_equal "organization needs a name" "bad_target" "$(resolved '.problem_details[0].code')"
settings '{"registration": {"scope": "repository", "target": "owner"}}'
expect_equal "repository needs owner/name" "bad_target" "$(resolved '.problem_details[0].code')"
settings '{"registration": {"scope": "repository", "target": "owner/repo"}}'
expect_equal "valid repository" "0" "${#GR_PROBLEMS[@]}"
expect_equal "runners page of the repository" "http://homeassistant.local:3000/owner/repo/settings/actions/runners" "$(resolved '.gitea.runners_page')"
settings '{"registration": {"scope": "user", "target": "ignored"}}'
expect_equal "target is dropped for other scopes" "" "$GR_TARGET"
pass "scope and target are checked"

settings '{"gitea_url": "git.example.com"}'
expect_equal "address without scheme" "bad_gitea_url" "$(resolved '.problem_details[0].code')"
settings '{"gitea_url": "https://git.example.com/", "advanced": {"ca_certificate": "missing.pem"}}'
expect_equal "missing certificate" "ca_missing" "$(resolved '.problem_details[0].code')"
settings '{"runner_name": "-bad"}'
expect_equal "invalid name" "bad_runner_name" "$(resolved '.problem_details[0].code')"
pass "addresses, certificates and names are checked"

# ---- runner configuration, read by the real binary ----------------------------------------------

settings '{"capacity": 3, "host_jobs": {"enabled": true, "home_assistant_api": true}, "advanced": {"docker_in_jobs": true, "debug_logging": true}}'
write_runner_config
expect_equal "capacity in the configuration" "3" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get runner.capacity)"
expect_equal "labels in the configuration" "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest-slim
home-assistant:host" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get runner.labels)"
expect_equal "job network" "hassio" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get container.network)"
expect_equal "name mapping for jobs" "--add-host=homeassistant.local:172.30.33.5" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get container.options)"
expect_equal "Docker socket reaches the jobs" "" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get container.docker_host)"
expect_equal "Home Assistant API address for jobs" "http://supervisor/core/api" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get runner.envs.HA_API_URL)"
expect_equal "registration file inside the data folder" "$DATA_DIR/.runner" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config runner-file)"
expect_equal "debug level" "debug" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get log.level)"
settings '{}'
write_runner_config
expect_equal "Docker socket stays out of the jobs" "-" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get container.docker_host)"
pass "the generated configuration is read by gitea-runner"

# ---- registration -------------------------------------------------------------------------------

reg_state() { jq -r '.state' "$REGISTRATION_STATE_FILE"; }
reg_code() { jq -r '.code' "$REGISTRATION_STATE_FILE"; }

settings '{"host_jobs": {"enabled": true}, "labels": []}'
write_runner_config
ensure_registered && fail "registration without credentials must not succeed"
expect_equal "needs credentials" "needs_credentials" "$(reg_state)"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "bad-token"}}'
ensure_registered && fail "a bad token must not register"
expect_equal "token rejected" "rejected" "$(reg_state)"
expect_equal "token rejected code" "registration_token_rejected" "$(reg_code)"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "odd-token"}}'
ensure_registered && fail "an unknown failure must not register"
expect_equal "unknown failure" "register_failed" "$(reg_code)"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "offline-token"}}'
(ensure_registered) && fail "an unreachable Gitea must not register" || code=$?
expect_equal "waits for Gitea, then tries again" "99" "$code"
expect_equal "waiting state" "waiting" "$(reg_state)"
pass "failed registrations are told apart"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "first-token"}}'
ensure_registered || fail "a good token registers"
expect_equal "registered" "registered" "$(reg_state)"
expect_equal "runner file written" "first-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"
expect_equal "runner name registered" "home-assistant" "$(jq -r '.name' "$RUNNER_FILE")"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "first-token"}}'
ensure_registered || fail "unchanged settings keep the registration"
expect_equal "same token does not register again" "first-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"

settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"registration_token": "second-token"}}'
ensure_registered || fail "a new token registers again"
expect_equal "new token registers again" "second-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"

settings '{"host_jobs": {"enabled": true}, "labels": [], "runner_name": "renamed", "registration": {"registration_token": "second-token"}}'
ensure_registered || fail "a new name registers again"
expect_equal "new name registers again" "renamed" "$(jq -r '.name' "$RUNNER_FILE")"

settings '{"host_jobs": {"enabled": true}, "labels": [], "runner_name": "another"}'
ensure_registered || fail "without a token the old registration stays"
expect_equal "registration kept without credentials" "renamed" "$(jq -r '.name' "$RUNNER_FILE")"
pass "the runner registers again only when its settings change"

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"access_token": "api-token", "scope": "instance"}}'
ensure_registered || fail "an access token fetches a registration token"
expect_equal "token from the API (POST unsupported, GET works)" "fresh-token-from-api" "$(jq -r '.registered_with' "$RUNNER_FILE")"

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"gitea_url": "http://127.0.0.1:3001", "host_jobs": {"enabled": true}, "labels": [], "registration": {"access_token": "api-token"}}'
ensure_registered || fail "old Gitea versions hand out tokens on the shorter path"
expect_equal "token from the old API" "fresh-token-from-old-api" "$(jq -r '.registered_with' "$RUNNER_FILE")"

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"host_jobs": {"enabled": true}, "labels": [], "registration": {"scope": "organization", "target": "nobody", "access_token": "api-token"}}'
ensure_registered && fail "an unknown organization must not register"
expect_equal "unknown scope" "scope_not_found" "$(reg_code)"
expect_equal "scope code arguments" "nobody" "$(jq -r '.args.target' "$REGISTRATION_STATE_FILE")"

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"gitea_url": "http://127.0.0.1:9", "host_jobs": {"enabled": true}, "labels": [], "registration": {"access_token": "api-token"}}'
(ensure_registered) && fail "an unreachable Gitea must not register" || code=$?
expect_equal "waits for Gitea with an access token" "99" "$code"
expect_equal "waiting for the API" "waiting" "$(reg_state)"
pass "registration tokens come from the Gitea API on both generations of it"

# ---- status -------------------------------------------------------------------------------------

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"host_jobs": {"enabled": true}, "registration": {"registration_token": "first-token"}}'
write_runner_config
ensure_registered
refresh_status >/dev/null
status="$RUNTIME_DIR/status.json"
expect_equal "Gitea reachable" "true" "$(jq -r '.gitea.reachable' "$status")"
expect_equal "Gitea version" "28.2.0" "$(jq -r '.gitea.version' "$status")"
expect_equal "registration state in the status" "registered" "$(jq -r '.registration.state' "$status")"
expect_equal "runner id in the status" "7" "$(jq -r '.registration.runner_id' "$status")"
expect_equal "runner is ready" "true" "$(jq -r '.runner.ready' "$status")"
expect_equal "runner version" "v5.2.2" "$(jq -r '.runner.version' "$status")"
expect_equal "jobs running" "1" "$(jq -r '.runner.jobs_running' "$status")"
expect_equal "jobs succeeded" "5" "$(jq -r '.runner.jobs_succeeded' "$status")"
expect_equal "jobs failed or cancelled" "3" "$(jq -r '.runner.jobs_failed' "$status")"
expect_equal "Docker available" "true" "$(jq -r '.docker.available' "$status")"
expect_equal "companion state" "started" "$(jq -r '.companions[0].state' "$status")"
expect_equal "no remote check without an access token" "unknown" "$(jq -r '.runner.remote.state' "$status")"
jq -e '.. | strings | select(test("secret|first-token"))' "$status" >/dev/null && fail "the status must not contain secrets"
pass "the status combines settings, registration and live checks"

jq '.gitea.url = "http://127.0.0.1:9"' "$RUNTIME_DIR/resolved.json" >"$fixture/resolved.tmp" && mv "$fixture/resolved.tmp" "$RUNTIME_DIR/resolved.json"
refresh_status >/dev/null
expect_equal "unreachable Gitea" "false" "$(jq -r '.gitea.reachable' "$status")"
expect_equal "unreachable Gitea code" "no_answer" "$(jq -r '.gitea.code' "$status")"
pass "an unreachable Gitea is explained with a code"

DOCKER_URL=http://127.0.0.1:9 refresh_status >/dev/null
expect_equal "Docker unavailable code" "docker_no_answer" "$(jq -r '.docker.code' "$status")"
pass "a missing Docker engine is explained with a code"

# ---- page backend and health check --------------------------------------------------------------

output="$(REQUEST_METHOD=GET bash "$RECHECK")"
grep -q '405' <<<"$output" || fail "recheck must refuse GET"
output="$(REQUEST_METHOD=POST bash "$RECHECK")"
jq -e . >/dev/null <<<"${output#*$'\r\n\r\n'}" || fail "recheck must answer with JSON"
pass "the recheck endpoint answers POST with the status"

: >"$RUNTIME_DIR/daemon"
bash "$HEALTHCHECK" || fail "health check must pass while the runner answers"
rm -f -- "$fixture/metrics/healthz"
bash "$HEALTHCHECK" && fail "health check must fail when the runner stops answering"
rm -f -- "$RUNTIME_DIR/daemon"
bash "$HEALTHCHECK" || fail "health check must pass while the app is idle"
pass "health check follows the runner"

"$REAL_RUNNER" --version | grep -q 'gitea-runner version' || fail "the runner binary must start"
pass "the runner binary starts"
