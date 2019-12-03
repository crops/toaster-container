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
    /usr/local/bin/pip3 install -r $BITBAKEDIR/toaster-requirements.txt
else
    pip install --upgrade pip && \
    pip install -r $BITBAKEDIR/toaster-requirements.txt
fi
