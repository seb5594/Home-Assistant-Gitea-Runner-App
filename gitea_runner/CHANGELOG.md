# Changelog

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
