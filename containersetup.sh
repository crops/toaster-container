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
    echo "Usage: containersetup.sh WORKDIR BRANCH"
    exit 1
fi

WORKDIR=$1
BRANCH=$2

cd $WORKDIR

git clone git://git.yoctoproject.org/poky --depth=1 --branch="${BRANCH}" && \

virtualenv toaster
. toaster/bin/activate

pip install --upgrade pip &&  \
pip install -r $WORKDIR/poky/bitbake/toaster-requirements.txt

# Run toaster once to setup the database so when the container is first ran,
# the user doesn't have to wait
. $WORKDIR/poky/oe-init-build-env build
. $WORKDIR/poky/bitbake/bin/toaster 

# Remove everything but the database
mv toaster.sqlite $WORKDIR
rm $WORKDIR/build -rf
