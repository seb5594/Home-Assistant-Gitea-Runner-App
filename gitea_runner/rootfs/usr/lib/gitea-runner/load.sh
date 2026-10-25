#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR
# Loads all libraries of the app in the order they depend on each other.
# The caller may define log_info, log_warning and log_error first (see common.sh).

LIB="${LIB:-/usr/lib/gitea-runner}"
for library in common probe settings runner-config registration status; do
  # shellcheck source=/dev/null
  source "${LIB}/${library}.sh"
done
unset library
