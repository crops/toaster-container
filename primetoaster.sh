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

set -e

if [ $# -ne 2 ]; then
    echo "Usage: primetoaster.sh WORKDIR POKYDIR"
    exit 1
fi

WORKDIR=$1
POKYDIR=$2

cd $WORKDIR

# Run toaster once to setup the database so when the container is first ran,
# the user doesn't have to wait
. $POKYDIR/oe-init-build-env build
. $POKYDIR/bitbake/bin/toaster

# Remove everything but the database
mv toaster.sqlite $WORKDIR
rm $WORKDIR/build -rf
