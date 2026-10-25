# Gitea Runner

Runs the Actions workflows of your Gitea on Home Assistant. Gitea only schedules workflows; a
runner is the program that executes them. This app is the [Gitea Runner](https://gitea.com/gitea/runner)
(`gitea-runner`, formerly `act_runner`), set up so that it needs nothing but a token.

The app page (*Open Web UI*) shows what works and what does not, in your browser's language
(German or English), and has workflows you can copy.

## Quick start

1. Install the app. It finds the Gitea app by itself; for another Gitea, enter its address under
   *Gitea address*.
2. In Gitea, enable Actions for the repository (*Settings → Repository → Enable Repository Actions*).
   Open the runners page of Gitea (the app page has a button) and copy the *registration token*.
   Instead of the token you can enter an *access token*, see below.
3. Enter the token under *Registration*, switch off *Protection mode* on the *Info* tab if you
   want jobs in containers, and start the app.

The runner then shows up in Gitea as "home-assistant". Put a workflow into
`.gitea/workflows/` of a repository and push it:

```yaml
name: Hello
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello from Home Assistant"
```

The registration is kept. You can empty the token afterwards; to register again (another Gitea,
another scope, a deleted runner), enter a new token and restart the app.

## Options

| Option | What it does |
| --- | --- |
| `gitea_url` | Address of your Gitea. Empty uses the Gitea app next to this one. |
| `registration.scope` | `instance` (all repositories, needs an administrator), `user`, `organization` or `repository`. |
| `registration.target` | Organization name, or `owner/repository`, for the scopes of the same name. |
| `registration.registration_token` | The token from the runners page of Gitea. |
| `registration.access_token` | Alternative: a personal access token. The app asks Gitea for the registration token itself, re-registers the runner when it was deleted in Gitea, and shows how Gitea sees the runner. |
| `runner_name` | Name in Gitea. Default `home-assistant`. |
| `capacity` | Jobs at the same time. Default 1, which is right for a Raspberry Pi. |
| `job_image` | `slim` (default), `standard` or `full`, see below. |
| `labels` | The `runs-on` names that are answered with a container. |
| `host_jobs.enabled` | Also run jobs inside this app (label `home-assistant`). |
| `host_jobs.home_assistant_api` | Give those jobs the Home Assistant API. |
| `advanced.*` | Extra labels, the app network, Docker inside jobs, privileged jobs, job timeout, cache, certificates, debug log. |

### The access token

A personal access token (Gitea → *Settings → Applications*) saves copying registration tokens and
lets the page show whether Gitea sees the runner as online. For the scope `instance` it must belong
to an administrator and have the `write:admin` scope; for an organization `write:organization`,
for a repository `write:repository`, for `user` `write:user`. The app only uses it to ask for the
registration token, to look at the runner and, when you change the registration, to remove the old
runner.

## Jobs in containers

The default. Every job runs in a fresh container on the Docker engine of Home Assistant OS and
disappears afterwards, so jobs cannot spoil each other or the app.

* The app needs Docker access: **switch off *Protection mode*** on the *Info* tab of the app. This is
  a deliberate decision, because anything that can use the Docker engine controls the whole host.
  Without it the app says so and only offers host jobs.
* `labels` picks the names workflows can use in `runs-on`. The image behind them follows `job_image`:
  `slim` is Node.js on Debian (a few hundred megabytes and enough for most workflows), `standard` has
  many build tools, `full` has everything GitHub's runners have and takes several gigabytes.
  Images come from `docker.gitea.com/runner-images`. Your own images work as extra labels:
  `python:docker://python:3.13-slim`.
* **App network.** Jobs join the Docker network `hassio`, so they reach Gitea, Home Assistant
  (`homeassistant:8123`) and the other apps by name. If Gitea announces itself under a name that only
  your own network knows (for example `http://homeassistant.local:3000`), jobs get that name mapped
  to the Gitea app, which makes `actions/checkout` work without any DNS setup.
* *Docker inside jobs* lets a job build images; it gives the job control of the Docker engine and
  with that of the host. Treat it like administrator access.

## Jobs on Home Assistant itself (host mode)

Switch on `host_jobs.enabled` and jobs with `runs-on: home-assistant` run inside this app, as root,
without a container. This is what workflows need that change your system: copy files into the
configuration, check it, reload Home Assistant.

Available inside those jobs: `git`, `node` (for JavaScript actions), `curl`, `jq`, bash, `apk`, and the
folders `/homeassistant` (config), `/share`, `/media`, `/backup` and `/ssl`; the last two are read-only.

With `host_jobs.home_assistant_api` the jobs also get `SUPERVISOR_TOKEN` and `HA_API_URL`
(`http://supervisor/core/api`):

```yaml
name: Reload Home Assistant
on: [push]
jobs:
  reload:
    runs-on: home-assistant
    steps:
      - name: Check the configuration
        run: |
          curl -fsS -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
            "$HA_API_URL/config/core/check_config" | tee check.json
          grep -q '"result": *"valid"' check.json
      - name: Reload everything that can be reloaded
        run: |
          curl -fsS -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
            "$HA_API_URL/services/homeassistant/reload_all"
```

**Be careful.** A workflow in a repository that may use a host runner can do anything the app can:
change your configuration and use the token. Register the runner for the repositories or
organization you trust (`registration.scope`), and keep host jobs off if you do not need them.
Without `home_assistant_api` the Supervisor token is removed from the runner's environment.

## Working with the other apps

* **Gitea** (the app by alexbelgium): found automatically. Actions are on by default in current
  Gitea versions; if the page says the registration is refused for the scope, check
  `[actions] ENABLED = true` in `app.ini`.
* **Gitea MCP Server**: Claude and Assist can look at workflow runs and start them with the toolset
  `actions`.
* **Home Assistant Git Exporter**: every export is a push, so a workflow with `on: push` runs after
  every export. A host job can then check the configuration of the repository against the running
  system.
* **Rsync Local**: it copies `/share` to your USB drive. A host job that writes build results or
  reports to `/share` gets them backed up that way.

The app page lists which of these apps are installed.

## Updates and backups

The version of the runner is the one of the Docker image `gitea/runner` that the app was built with.
New upstream releases arrive as new versions of this app. Home Assistant backups contain the
registration of the runner (so a restored backup keeps its identity), but not the caches and
workspaces, which can grow large.

## Troubleshooting

* **"The app has no access to Docker"**: switch off *Protection mode* on the *Info* tab and restart.
* **The runner is registered but offline in Gitea**: the page shows whether the runner process is
  connected. Gitea takes about a minute to notice a new runner.
* **Registration refused**: the registration token belongs to one scope. A token from the runners page
  of an organization only registers runners for that organization. Copy a fresh one.
* **`actions/checkout` cannot reach Gitea**: Gitea announces its `ROOT_URL` to the jobs. If jobs cannot
  look that address up, set `ROOT_URL` in Gitea to an address your network resolves, or keep the
  *app network* switched on (see above).
* **Debug logging** shows what the runner and Gitea say to each other. It can contain private data.
