#!/bin/bash
# Copyright (C) 2016 Intel Corporation
# Copyright (C) 2022 Konsulko Group
#
# SPDX-License-Identifier: GPL-2.0-only
#
# This script is meant to be consumed by GitHub Actions.
set -e

function getrev {
    docker run -it --rm=true --entrypoint=git -w /home/usersetup/poky \
        local:latest --no-pager log --pretty=%h -1 | tr -d '\r'
}

# Don't deploy on pull requests because it could just be junk code that won't
# get merged
if ([ "${GITHUB_EVENT_NAME}" = "push" ] || [ "${GITHUB_EVENT_NAME}" = "workflow_dispatch" ] || [ "${GITHUB_EVENT_NAME}" = "schedule" ]) && [ "${GITHUB_REF}" = "refs/heads/master" ]; then

    REPOS="${REPO}"

    # If this is the LATEST_RELEASE_REPO we also need to push to the
    # FLOATING_REPO
    if [ "${LATEST_RELEASE_REPO}" = "${REPO}" ]; then
        REPOS="${REPOS} ${FLOATING_REPO}"
    fi

    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

    for repo in $REPOS; do
        docker tag local $repo:${DOCKERHUB_TAG}

        # Also add a timestamp tag with the committish so that we know when it
        # was built and what it contains
        docker tag local $repo:${DOCKERHUB_TAG}-$(date -u +%Y%m%d%H%M)-$(getrev)

        docker push $repo
    done

    # Show the images so we know what should have been pushed
    docker images

else
    echo "Not pushing since build was triggered by a pull request."
fi
