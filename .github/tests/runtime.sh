#!/usr/bin/env bash
set -Eeuo pipefail
# bashio starts the services with the same strictness; a library that only works without it fails
# in Home Assistant, not here.
shopt -s inherit_errexit

# Runs inside the built image (release pipeline). Mocked Gitea servers answer the app's libraries;
# a stand-in for the registration plays the part of Gitea's runner service, while the real
# gitea-runner binary reads the generated configuration.
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

# ---- fixtures: Gitea on 3000, the metrics of the runner on 9101 --------------------------------

mkdir -p "$fixture"/gitea/api/v1 "$fixture"/metrics
echo '{"version":"28.2.0"}' >"$fixture/gitea/api/v1/version"
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

serve "$fixture/gitea" 3000
serve "$fixture/metrics" 9101
wait_for http://127.0.0.1:3000/api/v1/version
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

export RUNTIME_DIR="$fixture/run" OPTIONS_FILE="$fixture/options.json" DATA_DIR="$fixture/data" VERSION_FILE="$fixture/version"
mkdir -p "$RUNTIME_DIR" "$DATA_DIR"
echo 1.0.0-alpha.99 >"$VERSION_FILE"

# options <json>: the app options as the Supervisor would store them (the default Gitea address
# is replaced by the mock).
options() {
  jq -n --argjson overrides "$1" '
    {gitea_url: "http://127.0.0.1:3000", registration_token: "", runner_name: "", labels: ["home-assistant"],
     capacity: 1, advanced: {ignore_certificate_errors: false, debug_logging: false}}
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

settings '{"gitea_url": ""}'
expect_equal "default address" "http://db21ed7f-gitea:3000" "$GR_GITEA_URL"
expect_equal "default source" "default" "$GR_GITEA_SOURCE"
expect_equal "default name" "home-assistant" "$GR_NAME"
expect_equal "host name of the app" "$(hostname)" "$GR_APP_HOSTNAME"
expect_equal "version of the image" "1.0.0-alpha.99" "$GR_APP_VERSION"
expect_equal "no problems" "0" "${#GR_PROBLEMS[@]}"
pass "without an address the Gitea app of alexbelgium is used"

settings '{"gitea_url": " https://git.example.com/api/v1/ "}'
expect_equal "configured address is cleaned up" "https://git.example.com" "$GR_GITEA_URL"
expect_equal "configured source" "url" "$GR_GITEA_SOURCE"
settings '{"gitea_url": "git.example.com"}'
expect_equal "address without scheme" "bad_gitea_url" "$(resolved '.problem_details[0].code')"
expect_equal "address in the problem" "git.example.com" "$(resolved '.problem_details[0].args.url')"
pass "addresses are cleaned up and checked"

settings '{"runner_name": "-bad"}'
expect_equal "invalid name" "bad_runner_name" "$(resolved '.problem_details[0].code')"
settings '{"labels": ["home-assistant", "bad label!", "ci", "ci"]}'
expect_equal "invalid label" "bad_label" "$(resolved '.problem_details[0].code')"
expect_equal "labels without the invalid one and without duplicates" "home-assistant ci" "${GR_LABELS[*]}"
settings '{"labels": []}'
expect_equal "no label" "no_labels" "$(resolved '.problem_details[0].code')"
pass "names and labels are checked"

# ---- CPUs for the jobs ---------------------------------------------------------------------------

cpus="$fixture/cpus"
printf 'Name:\tx\nCpus_allowed_list:\t0-7\n' >"$cpus"
expect_equal "one of eight CPUs" "7" "$(cpu_list 1 "$cpus")"
expect_equal "three of eight CPUs" "5,6,7" "$(cpu_list 3 "$cpus")"
expect_equal "all CPUs when asked for all" "" "$(cpu_list 8 "$cpus")"
expect_equal "all CPUs when asked for more" "" "$(cpu_list 16 "$cpus")"
printf 'Cpus_allowed_list:\t0,2-3\n' >"$cpus"
expect_equal "ranges and single CPUs" "2,3" "$(cpu_list 2 "$cpus")"
printf 'Cpus_allowed_list:\t0\n' >"$cpus"
expect_equal "a single CPU is left alone" "" "$(cpu_list 1 "$cpus")"
printf 'Name:\tx\n' >"$cpus"
expect_equal "no information, no limit" "" "$(cpu_list 1 "$cpus")"
command -v taskset >/dev/null || fail "taskset is missing, the CPU limit would not work"
taskset -c "$(taskset -cp $$ | sed 's/.*: //; s/[-,].*//')" true || fail "taskset cannot set the CPUs"
pass "jobs are limited to the last CPUs and taskset works"

# ---- runner configuration, read by the real binary ----------------------------------------------

settings '{"capacity": 3, "labels": ["home-assistant", "ci"], "advanced": {"debug_logging": true}}'
write_runner_config
expect_equal "capacity in the configuration" "3" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get runner.capacity)"
expect_equal "labels in the configuration" "home-assistant:host
ci:host" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get runner.labels)"
expect_equal "registration file inside the data folder" "$DATA_DIR/.runner" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config runner-file)"
expect_equal "debug level" "debug" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get log.level)"
expect_equal "metrics stay on the loopback address" "127.0.0.1:9101" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get metrics.addr)"
settings '{}'
write_runner_config
expect_equal "info level" "info" "$("$REAL_RUNNER" -c "$RUNNER_CONFIG" config get log.level)"
pass "the generated configuration is read by gitea-runner"

# ---- registration -------------------------------------------------------------------------------

reg_state() { jq -r '.state' "$REGISTRATION_STATE_FILE"; }
reg_code() { jq -r '.code' "$REGISTRATION_STATE_FILE"; }

settings '{}'
write_runner_config
ensure_registered && fail "registration without a token must not succeed"
expect_equal "needs credentials" "needs_credentials" "$(reg_state)"

settings '{"registration_token": "bad-token"}'
ensure_registered && fail "a bad token must not register"
expect_equal "token rejected" "rejected" "$(reg_state)"
expect_equal "token rejected code" "registration_token_rejected" "$(reg_code)"

settings '{"registration_token": "odd-token"}'
ensure_registered && fail "an unknown failure must not register"
expect_equal "unknown failure" "register_failed" "$(reg_code)"

settings '{"registration_token": "offline-token"}'
(ensure_registered) && fail "an unreachable Gitea must not register" || code=$?
expect_equal "waits for Gitea, then tries again" "99" "$code"
expect_equal "waiting state" "waiting" "$(reg_state)"
pass "failed registrations are told apart"

settings '{"registration_token": "first-token"}'
ensure_registered || fail "a good token registers"
expect_equal "registered" "registered" "$(reg_state)"
expect_equal "runner file written" "first-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"
expect_equal "runner name registered" "home-assistant" "$(jq -r '.name' "$RUNNER_FILE")"

settings '{"registration_token": "first-token"}'
ensure_registered || fail "unchanged settings keep the registration"
expect_equal "same token does not register again" "first-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"

settings '{"registration_token": "second-token"}'
ensure_registered || fail "a new token registers again"
expect_equal "new token registers again" "second-token" "$(jq -r '.registered_with' "$RUNNER_FILE")"

settings '{"registration_token": "second-token", "runner_name": "renamed"}'
ensure_registered || fail "a new name registers again"
expect_equal "new name registers again" "renamed" "$(jq -r '.name' "$RUNNER_FILE")"

settings '{"runner_name": "another"}'
ensure_registered || fail "without a token the old registration stays"
expect_equal "registration kept once the token is removed" "renamed" "$(jq -r '.name' "$RUNNER_FILE")"
expect_equal "and it is reported as registered" "registered" "$(reg_state)"
pass "the runner registers again only when its settings change"

# ---- status -------------------------------------------------------------------------------------

rm -f -- "$RUNNER_FILE" "$FINGERPRINT_FILE"
settings '{"registration_token": "first-token", "labels": ["home-assistant", "ci"]}'
write_runner_config
ensure_registered
refresh_status >/dev/null
status="$RUNTIME_DIR/status.json"
expect_equal "Gitea reachable" "true" "$(jq -r '.gitea.reachable' "$status")"
expect_equal "Gitea version" "28.2.0" "$(jq -r '.gitea.version' "$status")"
expect_equal "registration state in the status" "registered" "$(jq -r '.registration.state' "$status")"
expect_equal "runner name in the status" "home-assistant" "$(jq -r '.registration.name' "$status")"
expect_equal "runner is ready" "true" "$(jq -r '.runner.ready' "$status")"
expect_equal "runner version" "v5.2.2" "$(jq -r '.runner.version' "$status")"
expect_equal "jobs running" "1" "$(jq -r '.runner.jobs_running' "$status")"
expect_equal "jobs succeeded" "5" "$(jq -r '.runner.jobs_succeeded' "$status")"
expect_equal "jobs failed or cancelled" "3" "$(jq -r '.runner.jobs_failed' "$status")"
expect_equal "labels in the status" "home-assistant,ci" "$(jq -r '.runner.labels | join(",")' "$status")"
jq -e '.. | strings | select(test("secret|first-token"))' "$status" >/dev/null && fail "the status must not contain secrets"
pass "the status combines settings, registration and live checks"

jq '.gitea.url = "http://127.0.0.1:9"' "$RUNTIME_DIR/resolved.json" >"$fixture/resolved.tmp" && mv "$fixture/resolved.tmp" "$RUNTIME_DIR/resolved.json"
refresh_status >/dev/null
expect_equal "unreachable Gitea" "false" "$(jq -r '.gitea.reachable' "$status")"
expect_equal "unreachable Gitea code" "no_answer" "$(jq -r '.gitea.code' "$status")"
expect_equal "reason of the closed port" "refused" "$(jq -r '.gitea.args.reason' "$status")"
pass "an unreachable Gitea is explained with a code"

# ---- page backend and health check --------------------------------------------------------------

output="$(REQUEST_METHOD=GET bash "$RECHECK")"
grep -q '405' <<<"$output" || fail "recheck must refuse GET"
output="$(REQUEST_METHOD=POST bash "$RECHECK")"
jq -e . >/dev/null <<<"${output#*$'\r\n\r\n'}" || fail "recheck must answer with JSON"
pass "the recheck endpoint answers POST with the status"

for page in index.html app.js style.css; do
  test -s "${WEB_DIR:-/usr/share/gitea-runner/web}/$page" || fail "$page is missing"
done
pass "the app page files are in the image"

: >"$RUNTIME_DIR/daemon"
bash "$HEALTHCHECK" || fail "health check must pass while the runner answers"
rm -f -- "$fixture/metrics/healthz"
bash "$HEALTHCHECK" && fail "health check must fail when the runner stops answering"
rm -f -- "$RUNTIME_DIR/daemon"
bash "$HEALTHCHECK" || fail "health check must pass while the app is idle"
pass "health check follows the runner"

"$REAL_RUNNER" --version | grep -q 'gitea-runner version' || fail "the runner binary must start"
pass "the runner binary starts"
