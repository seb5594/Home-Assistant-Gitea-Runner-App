<!-- header:begin (generated from project metadata) -->
<h1 align="center">Gitea Runner</h1>

<p align="center">
  <img src="https://raw.githubusercontent.com/seb5594/Home-Assistant-Gitea-Runner-App/dev/gitea_runner/logo.png" alt="Gitea Runner" width="286" height="160">
</p>

---

<p align="center">
  <a href="https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fseb5594%2FHome-Assistant-Apps"><img src="https://img.shields.io/static/v1?label=Home%20Assistant&amp;message=Add%20app%20repository&amp;color=18BCF2&amp;logo=homeassistant&amp;logoColor=white&amp;style=for-the-badge" alt="Home Assistant" height="28"></a>
  <a href="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App/releases"><img src="https://img.shields.io/static/v1?label=version&amp;message=1.0.0-dev5&amp;color=1877A5&amp;style=for-the-badge" alt="version" height="28"></a>
  <img src="https://img.shields.io/static/v1?label=image%20pulls&amp;message=12&amp;color=1877A5&amp;style=for-the-badge" alt="image pulls" height="28"><br>
  <img src="https://img.shields.io/static/v1?label=arch&amp;message=amd64%20%C2%B7%20aarch64&amp;color=157F71&amp;style=flat" alt="arch" height="20">
  <img src="https://img.shields.io/static/v1?label=stage&amp;message=experimental&amp;color=2F855A&amp;style=flat" alt="stage" height="20">
  <img src="https://img.shields.io/static/v1?label=ingress&amp;message=enabled&amp;color=7C3AED&amp;style=flat" alt="ingress" height="20">
  <img src="https://img.shields.io/static/v1?label=image%20size&amp;message=amd64%20132.7%20%C2%B7%20aarch64%20137.9%20MiB&amp;color=157F71&amp;style=flat" alt="image size" height="20"><br>
  <a href="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App/stargazers"><img src="https://img.shields.io/github/stars/seb5594/Home-Assistant-Gitea-Runner-App?label=stars&amp;style=flat" alt="stars" height="20"></a>
  <a href="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App/issues"><img src="https://img.shields.io/github/issues/seb5594/Home-Assistant-Gitea-Runner-App?label=issues&amp;style=flat" alt="issues" height="20"></a>
  <img src="https://img.shields.io/static/v1?label=runtime%20tests&amp;message=12%20passed&amp;color=2F855A&amp;style=flat" alt="runtime tests" height="20">
  <a href="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/seb5594/Home-Assistant-Gitea-Runner-App/ci.yml?branch=dev&amp;label=checks&amp;style=flat" alt="checks" height="20"></a>
  <a href="https://github.com/seb5594/Home-Assistant-Gitea-Runner-App#license"><img src="https://img.shields.io/github/license/seb5594/Home-Assistant-Gitea-Runner-App?label=license&amp;style=flat" alt="license" height="20"></a><br>
  <a href="https://paypal.me/seb5594"><img src="https://img.shields.io/static/v1?label=Support&amp;message=PayPal&amp;color=0070BA&amp;logo=paypal&amp;logoColor=white&amp;style=for-the-badge" alt="PayPal" height="40"></a>
  <a href="https://buymeacoffee.com/seb5594"><img src="https://img.shields.io/static/v1?label=Support&amp;message=Buy%20Me%20a%20Coffee&amp;color=FFDD00&amp;logo=buy-me-a-coffee&amp;logoColor=black&amp;style=for-the-badge" alt="Buy Me a Coffee" height="40"></a>
</p>
<!-- header:end -->

Brings the [Gitea Runner](https://gitea.com/gitea/runner) to Home Assistant. Gitea Actions workflows
need a runner to execute them; with this app your own Gitea builds, tests and deploys on your own
hardware, without a cloud service.

> **Pre-release.** The versions are `dev` pre-releases: tested against a real Gitea, not yet on many
> installations. Please report what you see.

* **Minimal permissions.** No Docker, no Supervisor or Home Assistant API, no folders, no host network.
  The address of the [Gitea app by alexbelgium](https://github.com/alexbelgium/hassio-addons/tree/master/gitea)
  is already filled in; you copy one registration token, once.
* **Isolated.** Jobs run inside the app with a low priority and the highest OOM score, so a runaway
  job is stopped before it can take Home Assistant down.
* **Honest about limits.** No container jobs, no `docker build`, and Alpine instead of glibc. The
  documentation says what that means and how to run heavy builds (ESPHome, images) on another machine.
* **Guided.** The app page shows what works, has the setup steps and workflows to copy for deploying
  through the Home Assistant API or SSH. English and German.

## Install

In Home Assistant open **Settings → Apps → App store → ⋮ → Repositories**, add
`https://github.com/seb5594/Home-Assistant-Gitea-Runner-App` and install **Gitea Runner**.
Older versions call these *Add-ons* and *Add-on store*. Setup, workflows and limits are in the
[documentation](gitea_runner/DOCS.md).

## How it fits together

```text
Gitea (app or any other) ◄── the runner asks for jobs ── Gitea Runner (this app)
                                                           └─ jobs run inside this app
```

The runner is the official binary. The app wires it into Home Assistant: it registers the runner,
generates its configuration and writes the setup guide.

## Development

```text
gitea_runner/
  config.yaml, translations/    options and their labels
  rootfs/usr/lib/gitea-runner/  shell libraries: options, registration, checks, status
  rootfs/etc/s6-overlay/        the runner service and the app page service
  rootfs/usr/share/gitea-runner/ the app page (plain HTML, CSS and JavaScript)
.github/tests/runtime.sh        runs inside the built image
.github/workflows/upstream.yml  follows the releases of Gitea Runner
```

The runtime test runs the libraries against a mocked Gitea with a stand-in for the registration, and
lets the real `gitea-runner` read the generated configuration.

Gitea Runner is pinned in the `Dockerfile`. A scheduled workflow looks for a newer release and
commits the new pin together with a new app version and changelog entry, so each upstream release
becomes a release of this app by itself. Renovate pull requests for the base image and the Alpine
packages get their version bump the same way. See `.github/scripts/upstream.py`.

<!-- support:begin (generated, shared text) -->
## Say thanks

All my projects are built in my spare time, just for the fun of it. Still, they take a lot of time and care, and many of the smart home gadgets I buy end up here because I want to make them cloud-free and smart-home ready. Every bit of support means a lot to me.

If my work helped you or turned out to be useful, show your appreciation with a hot drink for my next sleepless night.

[![PayPal](https://img.shields.io/static/v1?label=Support&message=PayPal&color=0070BA&logo=paypal&logoColor=white&style=for-the-badge)](https://paypal.me/seb5594) [![Buy Me a Coffee](https://img.shields.io/static/v1?label=Support&message=Buy%20Me%20a%20Coffee&color=FFDD00&logo=buy-me-a-coffee&logoColor=black&style=for-the-badge)](https://buymeacoffee.com/seb5594)
<!-- support:end -->

<!-- license:begin (generated from the license file) -->
## License

[![license](https://img.shields.io/static/v1?label=license&message=MIT&color=5B6770&style=flat)](LICENSE)

Published under the [MIT License](LICENSE).
<!-- license:end -->
