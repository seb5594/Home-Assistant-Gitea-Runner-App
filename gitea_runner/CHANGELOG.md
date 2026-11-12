# Changelog

## 6.0.0

* Match the app version to the pinned upstream image version (6.0.0); the packaged upstream software is unchanged.
* Refresh the Git package pin to 2.54.1-r0 because Alpine no longer provides the previously pinned build.
* Refresh the unavailable Node.js package pin to 24.22.3-r0 within the same major version.
* Select the available Node.js patch per architecture: 24.22.3-r0 on amd64 and 24.22.1-r1 on aarch64.
* Keep daily automatic updates within the current upstream major version.
* Require Renovate Dependency Dashboard approval and manual PR merge for major Docker image updates.
* Keep historical Alpha release notes below; the Home Assistant wrapper remains experimental.

## 1.0.0-alpha.14

* 📦 Update gitea/runner to 6.0.0 (was 5.4.1).

## 1.0.0-alpha.13

* 📦 Update gitea/runner to 5.4.1 (was 5.4.0).

## 1.0.0-alpha.12

* 📦 Update gitea/runner to 5.4.0 (was 5.2.4).

## 1.0.0-alpha.11

* Update the base image and packaged dependencies to available release versions; restore reproducible CI builds.

## 1.0.0-alpha.10

* New version scheme: pre-releases are called Alpha from now on (earlier ones were 1.0.0-dev1 to 1.0.0-dev6). The releases and the badge show just "Alpha 10".

## 1.0.0-dev6

* Dependencies: update alpine base and packages (base image 3.24-2026.10.1, curl 8.23.0-r0).

## 1.0.0-dev5

* The CPU limit works in the image: taskset comes from util-linux-misc, busybox does not have it. The pictures in the README point to the default branch.

## 1.0.0-dev4

* New option “CPU cores for jobs” (default 1): all jobs together may only use that many cores, the rest
  stays free for Home Assistant. A job that compiles or installs no longer takes a whole small
  device with it.

## 1.0.0-dev3

* The official Gitea logo with the name of the app as icon and logo. The license is MIT.

## 1.0.0-dev2

* **Minimal and isolated.** No Docker, no Supervisor or Home Assistant API, no folders. The app only
  needs the address of Gitea (default: the Gitea app by alexbelgium) and a registration token.
  Jobs run inside the app, as children of a runner with low CPU priority and the highest OOM score.
* New app page with tabs for the overview, the setup, workflow examples and safety and limits.
* Full documentation, including how to run heavy builds on a separate machine.

## 1.0.0-dev1

* First pre-release (not published).
