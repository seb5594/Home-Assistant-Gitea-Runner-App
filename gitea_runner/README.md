# Gitea Runner

Runs the Actions workflows of your own Gitea on Home Assistant, inside an isolated app.

* Minimal permissions: no access to Docker, the Supervisor or your files. The address of the Gitea
  app is filled in, you copy one registration token.
* Jobs run in the app with a low priority and are stopped first when memory runs short.
* The app page shows what works, in your language, and has workflows to copy.

> **Pre-release.** This is a `dev` version. Please report what you see.

Open the *Documentation* tab for setup, workflows, limits and heavy builds.
