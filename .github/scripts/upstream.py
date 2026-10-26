#!/usr/bin/env python3
"""Keeps the version of the app in step with the software it packages.

    upstream.py update               follow new releases of the upstream images pinned in the Dockerfile
    upstream.py bump NOTE [--base REF]
                                     raise the app version for a change that is already in the working tree

An upstream image is a pin the Dockerfile marks for Renovate:

    # renovate: datasource=docker depName=docker.io/gitea/runner
    ARG GITEA_RUNNER_VERSION=5.2.2

`update` asks Docker Hub for the newest release tag of such an image and, when it is newer, changes the
pin, raises the app version and adds a changelog entry. The app version moves like this:
1.0.0-alpha.3 becomes 1.0.0-alpha.4 (pre-releases count up), 1.2.3 becomes 1.2.4. A new version is what makes
the release pipeline publish the app again.

`bump` is for pull requests that change the app in another way (Renovate raising the base image or an
Alpine package). With --base it does nothing unless the app changed against that ref, and nothing when
the version was already raised there.

Results for the workflow go to $GITHUB_OUTPUT: changed (true/false) and version.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

PIN = re.compile(
    r"^# renovate: datasource=docker depName=docker\.io/(?P<repository>[\w.-]+/[\w.-]+)\n"
    r"ARG (?P<name>\w+)=(?P<version>\d+\.\d+\.\d+)$",
    re.MULTILINE,
)
RELEASE_TAG = re.compile(r"^\d+\.\d+\.\d+$")
VERSION_LINE = re.compile(r"^(version:\s*)([\"']?)([^\"'\s]+)([\"']?)\s*$", re.MULTILINE)
BUILD_VERSION = re.compile(r"^(ARG BUILD_VERSION=)(\S+)$", re.MULTILINE)


def find_app():
    """The app folder: the one below the repository root that holds config.yaml and Dockerfile."""
    for config in sorted(Path(".").glob("*/config.yaml")):
        if (config.parent / "Dockerfile").exists():
            return config.parent
    sys.exit("No app folder with config.yaml and Dockerfile found.")


def as_tuple(version):
    return tuple(int(part) for part in version.split("."))


def newest_release(repository):
    """The highest x.y.z tag of an image on Docker Hub."""
    url = f"https://hub.docker.com/v2/repositories/{repository}/tags?page_size=100&ordering=last_updated"
    request = urllib.request.Request(url, headers={"User-Agent": "upstream-follower"})
    with urllib.request.urlopen(request, timeout=30) as reply:
        tags = [entry["name"] for entry in json.load(reply)["results"]]
    releases = [tag for tag in tags if RELEASE_TAG.match(tag)]
    if not releases:
        sys.exit(f"{repository} has no release tags in its newest 100 tags.")
    return max(releases, key=as_tuple)


def next_version(version):
    """The version after this one: pre-releases count up, releases get a new patch number."""
    pre_release = re.fullmatch(r"(\d+\.\d+\.\d+-(?:alpha\.|dev))(\d+)", version)
    if pre_release:
        return f"{pre_release[1]}{int(pre_release[2]) + 1}"
    release = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
    if release:
        return f"{release[1]}.{release[2]}.{int(release[3]) + 1}"
    sys.exit(f"Cannot raise the version '{version}'.")


def read_version(config_text):
    match = VERSION_LINE.search(config_text)
    if not match:
        sys.exit("config.yaml has no version.")
    return match[3]


def release_app(app, note):
    """Raises the version in config.yaml and Dockerfile and adds the changelog entry. Returns it."""
    config_path, dockerfile_path, changelog_path = app / "config.yaml", app / "Dockerfile", app / "CHANGELOG.md"
    config = config_path.read_text()
    version = next_version(read_version(config))

    config_path.write_text(VERSION_LINE.sub(lambda m: f"{m[1]}{m[2]}{version}{m[4]}", config, count=1))
    dockerfile_path.write_text(BUILD_VERSION.sub(lambda m: f"{m[1]}{version}", dockerfile_path.read_text(), count=1))

    changelog = changelog_path.read_text()
    heading = "# Changelog\n"
    if not changelog.startswith(heading):
        sys.exit("CHANGELOG.md must start with '# Changelog'.")
    changelog_path.write_text(f"{heading}\n## {version}\n\n* {note}\n{changelog[len(heading):]}")
    return version


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def write_output(changed, version):
    print(f"changed={str(changed).lower()} version={version}")
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            output.write(f"changed={str(changed).lower()}\nversion={version}\n")


def update(app):
    dockerfile_path = app / "Dockerfile"
    dockerfile = dockerfile_path.read_text()
    notes = []
    for pin in list(PIN.finditer(dockerfile)):
        latest = newest_release(pin["repository"])
        if as_tuple(latest) > as_tuple(pin["version"]):
            dockerfile = dockerfile.replace(pin[0], pin[0].replace(f"={pin['version']}", f"={latest}"))
            notes.append(f"Update {pin['repository']} to {latest} (was {pin['version']}).")
    if not notes:
        write_output(False, read_version((app / "config.yaml").read_text()))
        return
    dockerfile_path.write_text(dockerfile)
    write_output(True, release_app(app, " ".join(notes)))


def bump(app, note, base):
    config_path = app / "config.yaml"
    if base:
        changed_files = git("diff", "--name-only", f"{base}...HEAD", "--", str(app)).split()
        base_version = read_version(git("show", f"{base}:{config_path}"))
        if not changed_files or read_version(config_path.read_text()) != base_version:
            write_output(False, read_version(config_path.read_text()))
            return
    write_output(True, release_app(app, note))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("update")
    bump_parser = commands.add_parser("bump")
    bump_parser.add_argument("note")
    bump_parser.add_argument("--base")
    arguments = parser.parse_args()

    app = find_app()
    if arguments.command == "update":
        update(app)
    else:
        bump(app, arguments.note, arguments.base)


if __name__ == "__main__":
    main()
