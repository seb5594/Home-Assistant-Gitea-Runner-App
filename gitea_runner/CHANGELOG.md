# Changelog

## 1.0.0-dev2

* **Minimal and isolated.** No Docker, no Supervisor or Home Assistant API, no folders. The app only
  needs the address of Gitea (default: the Gitea app by alexbelgium) and a registration token.
  Jobs run inside the app, as children of a runner with low CPU priority and the highest OOM score.
* New app page with tabs for the overview, the setup, workflow examples and safety and limits.
* Full documentation, including how to run heavy builds on a separate machine.

## 1.0.0-dev1

* First pre-release (not published).
