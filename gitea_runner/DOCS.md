# Gitea Runner

Runs the Actions workflows of your own Gitea: build, test and deploy when you push to a repository,
without a cloud service. Gitea only schedules workflows; a *runner* executes them. This app is the
[Gitea Runner](https://gitea.com/gitea/runner) (`gitea-runner`, formerly `act_runner`), set up so that
it needs nothing but a token.

It is built to be **small and isolated**: it has no access to Docker, the Supervisor or your files.
Read [Safety and limits](#safety-and-limits) to see what that means for your workflows.

**This is a pre-release (`dev` versions).** Expect rough edges and please report what you see.

## Contents

* [How it works](#how-it-works)
* [Quick start](#quick-start)
* [Options](#options)
* [Workflows](#workflows)
* [Safety and limits](#safety-and-limits)
* [Heavy builds](#heavy-builds)
* [Working with other apps](#working-with-other-apps)
* [Updates and backups](#updates-and-backups)
* [Troubleshooting](#troubleshooting)
* [Questions](#questions)

## How it works

```text
Gitea (app or any other) ◄── the runner asks for jobs ── Gitea Runner (this app)
                                                           └─ jobs run inside this app
```

The runner connects to your Gitea and asks, every few seconds, whether a job waits for it. A job
is one `jobs:` entry of a workflow whose `runs-on:` names one of the runner's *labels*. The runner
checks out the repository, runs the steps and reports the log back to Gitea. Nothing connects to
the app from outside.

The app page (**Open Web UI**) shows what works, in your language (English, or German when your
browser prefers it), has the registration steps and workflows to copy.

## Quick start

1. **Switch on Actions.** Current Gitea versions have Actions on. In a repository open Settings →
   Repository and enable *Actions*. If that section is missing, Actions are off for the whole
   Gitea (`ENABLED` in the `[actions]` section of `app.ini`).
2. **Copy a registration token.** In Gitea open the runners page and create a new runner. Where you
   open it decides who may use the runner:

   | Where | Who may use the runner |
   | --- | --- |
   | Site administration → Actions → Runners | every repository of the Gitea |
   | Organization → Settings → Actions → Runners | the repositories of that organization |
   | Repository → Settings → Actions → Runners | that repository only |

3. **Enter it here.** Paste the token as **Registration token** in the app configuration and start
   (or restart) the app. For a Gitea other than the Gitea app by alexbelgium, change **Gitea
   address** as well.
4. **Check.** The app page shows the runner as registered and connected; Gitea lists it as online
   after a short while. Then empty the token field: it is not needed any more.

To register again (another Gitea, another scope, a runner you deleted in Gitea), enter a **new**
token and restart the app. Changing the Gitea address or the runner name registers again, too.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `gitea_url` | `http://db21ed7f-gitea:3000` | Address of your Gitea: the Gitea app by alexbelgium. Another app: `http://<host name>:3000`; another machine: `https://git.example.com`. |
| `registration_token` | empty | The token from the runners page of Gitea. Needed once. |
| `runner_name` | `home-assistant` | The name shown in Gitea. |
| `labels` | `home-assistant` | The names for `runs-on`. All of them run jobs inside this app. Letters, digits, dots, dashes, underscores. |
| `capacity` | 1 | Jobs at the same time (1 to 4). |
| `advanced.ignore_certificate_errors` | off | Accept any certificate of Gitea. Only for a Gitea in your own network. |
| `advanced.debug_logging` | off | Detailed log, including what the runner exchanges with Gitea. Switch it off after troubleshooting. |

Invalid values do not stop the app. It keeps running, says what is wrong in the log and on the app
page, and starts as soon as the configuration is right.

## Workflows

Workflows are YAML files in `.gitea/workflows/` of a repository. The app page has these examples
with your label filled in; each can be copied.

**Hello**

```yaml
name: Hello
on: [push, workflow_dispatch]
jobs:
  hello:
    runs-on: home-assistant
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello from Home Assistant"
```

**Install what a job needs.** The image is Alpine Linux and jobs run as root, so `apk add` works
(it is gone again when the app restarts):

```yaml
      - run: |
          apk add --no-cache yamllint
          yamllint -d relaxed .
```

**Check and reload Home Assistant** through its API. Create a long-lived access token in your Home
Assistant profile (*Security*) and save it in Gitea as the secret `HA_TOKEN` (repository Settings →
Actions → Secrets). `homeassistant` is the name of Home Assistant on its internal network:

```yaml
name: Reload Home Assistant
on: [push]
jobs:
  reload:
    runs-on: home-assistant
    steps:
      - name: Check the configuration
        run: |
          curl -fsS -X POST -H "Authorization: Bearer ${{ secrets.HA_TOKEN }}" \
            http://homeassistant:8123/api/config/core/check_config | tee check.json
          grep -q '"result": *"valid"' check.json
      - name: Reload everything that can be reloaded
        run: |
          curl -fsS -X POST -H "Authorization: Bearer ${{ secrets.HA_TOKEN }}" \
            http://homeassistant:8123/api/services/homeassistant/reload_all
```

**Deploy to another machine over SSH.** `openssh-client` is in the image. Create a key pair, put the
public key on the target and save the private key as the secret `DEPLOY_KEY`:

```yaml
      - run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.DEPLOY_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -H target.example >> ~/.ssh/known_hosts
          tar -c lovelace | ssh deploy@target.example "tar -x -C /srv/lovelace"
```

Files stay inside the app: the runner cannot write to your Home Assistant configuration folder.
Use the API, SSH or a Git-based path (see [Working with other apps](#working-with-other-apps)).

## Safety and limits

**Why no Docker?** Jobs in containers need access to the Docker engine of Home Assistant OS, and
whoever may use that engine controls the whole host. A workflow that compiles firmware with
several parallel compilers has taken down Home Assistant itself that way. This app therefore runs
jobs inside its own container: memory shortage and runaway jobs hit the app, not the host. The price
is that there are no container jobs and no `docker build`.

What the app has:

* **No Supervisor or Home Assistant API, no folders, no Docker, no privileges.** Jobs reach your
  network like every app does, so other apps and Home Assistant can be called by their names.
* **Low priority.** The runner runs with a low CPU priority and the highest OOM score. Jobs inherit
  both: when memory runs out, the kernel stops a job before Home Assistant. It cannot prevent a
  device from slowing down when a job uses all memory, so keep `capacity` low on small devices.
* **No Supervisor token in jobs.** Workflows get secrets from Gitea, which you control per
  repository.

What it cannot do:

* **Programs that only exist for glibc.** Alpine Linux uses musl, so the toolchains of PlatformIO
  and ESPHome, or the downloads of `actions/setup-node` and `actions/setup-python`, do not run.
  `apk add` brings Alpine's own packages (Python, Node.js, Go and more); for everything else see
  [Heavy builds](#heavy-builds).
* **No `docker build`, no service containers, no `container:` in a workflow.**

**Who may use it.** Jobs run arbitrary commands as root inside the app. Register the runner only
for repositories and organizations you trust (see [Quick start](#quick-start), step 2) and be careful
with workflows triggered by pull requests from strangers.

## Heavy builds

Compiling firmware (ESPHome), building images or anything that needs glibc and Docker belongs on a
machine of its own, with memory to spare. Run the official runner there and register it with the
same Gitea, with a token from the same runners page:

```bash
docker run -d --name gitea-runner --restart unless-stopped \
  -e GITEA_INSTANCE_URL=https://git.example.com \
  -e GITEA_RUNNER_REGISTRATION_TOKEN=<token> \
  -e GITEA_RUNNER_NAME=build-machine \
  -e GITEA_RUNNER_LABELS=ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest \
  -v /var/run/docker.sock:/var/run/docker.sock -v runner-data:/data \
  docker.io/gitea/runner:5
```

Limit what a job may use there too, in its runner configuration:
`container.options: "--memory=4g --cpus=2"`. Workflows pick the machine by label (`ubuntu-latest`
for the build machine, `home-assistant` for this app), so both runners work side by side.

## Working with other apps

* **Gitea** (the app by alexbelgium): found at its default address, nothing to enter but the token.
* **Gitea MCP Server**: Claude, ChatGPT and Assist can look at workflow runs and start them with the
  tool group `actions`.
* **Home Assistant Git Exporter**: every export is a push, so a workflow with `on: push` runs after
  every export, for example a YAML lint or a configuration check.
* **Home Assistant itself**: through its API with a long-lived token kept as a Gitea secret (see
  [Workflows](#workflows)).

## Updates and backups

The version of the runner is the one of the Docker image `gitea/runner` that the app was built with.
New upstream releases arrive as new versions of this app by themselves. Home Assistant backups
contain the registration of the runner, so a restored backup keeps its identity, but not the caches
and workspaces, which can grow large.

## Troubleshooting

Open the app page and press **Check again**; it shows what the app sees. The log has the same
messages.

| Message | What to do |
| --- | --- |
| *A registration token is needed* | Copy one from the runners page of Gitea and enter it in the configuration. |
| *Gitea does not accept this registration token* | The token belongs to another Gitea, or was reset. Copy a fresh one. |
| *Gitea does not answer: the connection was refused* | Start the Gitea app, or check `gitea_url`. The runner keeps trying by itself. |
| *the TLS certificate is not trusted* | Use the `http://` address of the Gitea app inside Home Assistant, or switch on `ignore_certificate_errors` for a Gitea in your own network. |
| The runner is registered but a workflow never starts | The `runs-on` label of the workflow must be one of the runner's labels. Actions must be enabled for the repository. The registration scope must include the repository. |
| *Gitea shows the runner as offline* | It takes about a minute to notice a new runner. If it stays offline, the log tells why. |
| A step fails with "command not found" | The image is minimal. Install the program with `apk add`, see [Workflows](#workflows). |
| A tool fails with "not found" although the file exists | A glibc-only program on Alpine. See [Safety and limits](#safety-and-limits). |
| `actions/checkout` cannot reach Gitea | Gitea announces its `ROOT_URL` to the jobs. If the app cannot resolve that address, set `ROOT_URL` in Gitea to one that works inside Home Assistant's network. |

## Questions

**Can I run container jobs after all?** Not with this app, on purpose; see
[Safety and limits](#safety-and-limits) and [Heavy builds](#heavy-builds).

**Can a job change my Home Assistant configuration?** Not directly: it has no access to the
files. Through the API with a token you provide, it can do what that token allows.

**Why can't it find my Gitea by itself?** Detecting other apps needs access to the Supervisor,
which this app does not ask for. The default address matches the Gitea app of alexbelgium.

**Which language does the configuration use?** English by default. Home Assistant shows the German
texts when your profile language is German; the app page follows your browser the same way.

## Credits

The runner is the official [Gitea Runner](https://gitea.com/gitea/runner) (MIT license), used
unchanged. This app only wires it into Home Assistant. See `THIRD_PARTY_NOTICES.md`.
