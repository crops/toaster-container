#!/bin/bash
# Copyright (C) 2016 Intel Corporation
# Copyright (C) 2022 Konsulko Group
#
# SPDX-License-Identifier: GPL-2.0-only
#
# This script is meant to be consumed by GitHub Actions.
set -e

# Don't deploy on pull requests because it could just be junk code that won't
# get merged
if ([ "${GITHUB_EVENT_NAME}" = "push" ] || [ "${GITHUB_EVENT_NAME}" = "workflow_dispatch" ] || [ "${GITHUB_EVENT_NAME}" = "schedule" ]) && [ "${GITHUB_REF}" = "refs/heads/master" ]; then
    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
    docker push ${REPO}:latest
else
    echo "Not pushing since build was triggered by a pull request."
fi
