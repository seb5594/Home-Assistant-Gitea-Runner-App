#!/usr/bin/env bash
# shellcheck shell=bash
# Finds the Gitea app, and the other apps this one works with, through the Supervisor.
#
# The Supervisor lets an app with `hassio_api` read the info of other apps by slug.
# Listing all apps would need the "manager" role, so the known slugs are probed instead.

SUPERVISOR_URL="${SUPERVISOR_URL:-http://supervisor}"

# slug:port of the Gitea apps this app can connect to by itself.
#   db21ed7f_gitea  github.com/alexbelgium/hassio-addons (Gitea)
#   local_gitea     the same app installed from the local app folder
KNOWN_GITEA_APPS=("db21ed7f_gitea:3000" "local_gitea:3000")

# Apps that fit well with a runner, as id|name|slugs. The slug of an installed app starts with
# the first 8 characters of the SHA-1 of its repository URL (lower case), or with "local".
#   4c7fee11  github.com/seb5594/Home-Assistant-Apps
COMPANION_APPS=(
  "mcp|Gitea MCP Server|4c7fee11_gitea_mcp_server ada0e2b0_gitea_mcp_server local_gitea_mcp_server"
  "git_exporter|Home Assistant Git Exporter|4c7fee11_git-exporter d46539d0_git-exporter local_git-exporter"
  "rsync_local|Rsync Local|4c7fee11_rsync-local 81f86f9d_rsync-local local_rsync-local"
)

# supervisor_get <path>
# Body of a Supervisor API response; fails on HTTP errors.
supervisor_get() {
  curl -fsS --max-time 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN:-}" "${SUPERVISOR_URL}$1"
}

# find_gitea_app
# Prints one JSON object for the first installed Gitea app and fails when there is none:
#   {"slug", "name", "hostname", "state", "port", "ssl", "root_url"}
find_gitea_app() {
  local entry reply
  for entry in "${KNOWN_GITEA_APPS[@]}"; do
    reply="$(supervisor_get "/addons/${entry%%:*}/info" 2>/dev/null)" || continue
    jq -ce --arg slug "${entry%%:*}" --argjson port "${entry##*:}" '
      select(.result == "ok" and (.data.version // "") != "")
      | .data
      | {slug: $slug, name: .name, hostname: .hostname, state: .state, port: $port,
         ssl: (.options.ssl // false), root_url: (.options.ROOT_URL // "")}
    ' <<<"$reply" && return 0
  done
  return 1
}

# app_state <slug>
# The state of an installed app (started, stopped, ...); fails when it is not installed.
app_state() {
  local reply
  reply="$(supervisor_get "/addons/$1/info" 2>/dev/null)" || return 1
  jq -er 'select(.result == "ok" and (.data.version // "") != "") | .data.state' <<<"$reply"
}

# find_companions
# A JSON list of the installed apps from COMPANION_APPS: [{"id", "name", "slug"}]
find_companions() {
  local entry id name slugs slug found='[]'
  for entry in "${COMPANION_APPS[@]}"; do
    IFS='|' read -r id name slugs <<<"$entry"
    for slug in $slugs; do
      if app_state "$slug" >/dev/null; then
        found="$(jq -c --arg id "$id" --arg name "$name" --arg slug "$slug" '. + [{id: $id, name: $name, slug: $slug}]' <<<"$found")"
        break
      fi
    done
  done
  printf '%s\n' "$found"
}

# own_app_info
# {"hostname", "version"} of this app, with fallbacks for runs outside the Supervisor.
own_app_info() {
  local reply
  reply="$(supervisor_get /addons/self/info 2>/dev/null)" || reply='{}'
  jq -c --arg fallback "$(hostname)" '
    {hostname: (.data.hostname // $fallback), version: (.data.version // "unknown")}
  ' <<<"$reply"
}
