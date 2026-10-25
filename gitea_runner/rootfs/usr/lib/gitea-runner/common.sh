#!/usr/bin/env bash
# shellcheck shell=bash
# Helpers shared by the start script, the status page and the tests.
#
# The caller may define log_info, log_warning and log_error before sourcing this file
# (the start script maps them to bashio); the fallbacks print to stderr.

OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"
RUNTIME_DIR="${RUNTIME_DIR:-/run/gitea-runner}"
# The image records its own version here (see the Dockerfile).
VERSION_FILE="${VERSION_FILE:-/etc/gitea-runner/version}"

declare -F log_info >/dev/null || log_info() { printf '[INFO] %s\n' "$*" >&2; }
declare -F log_warning >/dev/null || log_warning() { printf '[WARNING] %s\n' "$*" >&2; }
declare -F log_error >/dev/null || log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# option <dotted.path> [default]
# Value of an app option. Empty values count as "not set" and give the default.
option() {
  jq -r --arg path "$1" --arg fallback "${2:-}" '
    getpath($path | split(".")) as $value
    | if $value == null or $value == "" then $fallback else ($value | tostring) end
  ' "$OPTIONS_FILE"
}

# option_list <dotted.path>
# Items of a list option, comma separated.
option_list() {
  jq -r --arg path "$1" 'getpath($path | split(".")) // [] | join(",")' "$OPTIONS_FILE"
}

# trim_url <url>
# The URL without surrounding blanks and trailing slashes.
trim_url() {
  local url="${1//[[:space:]]/}"
  while [[ "$url" == */ ]]; do
    url="${url%/}"
  done
  printf '%s' "$url"
}

is_http_url() {
  [[ "$1" =~ ^https?://[^/[:space:]]+(/[^[:space:]]*)?$ ]]
}

# An origin is scheme and host (with optional port), nothing else.
is_https_origin() {
  [[ "$1" =~ ^https://[^/[:space:]]+$ ]]
}

# message <code> <english text> [name value ...]
# One message as JSON; the arguments become the "args" object.
message() {
  local code="$1" text="$2" args='{}'
  shift 2
  while (($# >= 2)); do
    args="$(jq -c --arg name "$1" --arg value "$2" '. + {($name): $value}' <<<"$args")"
    shift 2
  done
  jq -nc --arg code "$code" --arg text "$text" --argjson args "$args" '{code: $code, text: $text, args: $args}'
}

# set_error <name> <code> <english text> [name value ...]
# Sets <name>_error (the text) and <name>_msg (the message JSON) in the calling function.
set_error() {
  local name="$1"
  shift
  printf -v "${name}_error" '%s' "$2"
  printf -v "${name}_msg" '%s' "$(message "$@")"
}

# yaml_string <text>
# The text as a quoted YAML scalar (JSON strings are valid YAML).
yaml_string() {
  jq -Rn --arg text "$1" '$text'
}

# nap <seconds>
# Sleeps in a way that lets the TERM trap of the start script run at once.
nap() {
  sleep "$1" &
  wait $!
}

# option_lines <dotted.path>
# Items of a list option, one per line.
option_lines() {
  jq -r --arg path "$1" 'getpath($path | split(".")) // [] | .[]' "$OPTIONS_FILE"
}

# json_list [json ...]
# The arguments (JSON values, empty ones skipped) as one JSON array.
json_list() {
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && printf '%s\n' "$item"
  done | jq -sc . || true
}

# own_app_info
# {"hostname", "version"} of this app. The host name is the slug with dashes for underscores.
own_app_info() {
  jq -nc --arg hostname "$(hostname)" --arg version "$(cat "$VERSION_FILE" 2>/dev/null || echo unknown)" \
    '{hostname: $hostname, version: $version}'
}
