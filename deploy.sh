#!/bin/bash
# Copyright (C) 2016 Intel Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# This script is meant to be consumed by travis. It's very simple but running
# a loop in travis.yml isn't a great thing.
set -e

function getrev {
    docker run -it --rm=true --entrypoint=git -w /home/usersetup/poky \
        local:latest --no-pager log --pretty=%h -1 | tr -d '\r'
}

# Don't deploy on pull requests because it could just be junk code that won't
# get merged
if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then
    REPOS="${REPO}"

    # If this is the LATEST_RELEASE_REPO we also need to push to the
    # FLOATING_REPO
    if [ "${LATEST_RELEASE_REPO}" = "${REPO}" ]; then
        REPOS="${REPOS} ${FLOATING_REPO}"
    fi

    docker login -e $DOCKER_EMAIL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

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
