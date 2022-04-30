#!/bin/bash
# Copyright (C) 2016 Intel Corporation
# Copyright (C) 2022 Konsulko Group
#
# SPDX-License-Identifier: GPL-2.0-only
#

# The sole purpose of this script is to only install the python3 version of
# the requirements if necessary. Unconditionally trying to install using
# python3 on an older toaster-requirements.txt will fail.
set -e

if [ $# -ne 1 ]; then
    echo "Usage: pipinstall.sh BITBAKEDIR"
    exit 1
fi

BITBAKEDIR=$1


if grep '#!/usr/bin/env python3' $BITBAKEDIR/bin/bitbake >& /dev/null; then
    pip3 install --upgrade pip && \
    export PATH="${PATH}:/home/usersetup/.local/bin" && \
    /home/usersetup/.local/bin/pip3 install -r $BITBAKEDIR/toaster-requirements.txt
else
    pip install --upgrade pip && \
    pip install -r $BITBAKEDIR/toaster-requirements.txt
fi
