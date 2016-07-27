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

workdir="${1}"

# If it doesn't already exist copy the toaster database from the container
# so that it doesn't have to be created again
bootstrap="/home/usersetup"
builddir="${workdir}/build"
toasterdb="${builddir}/toaster.sqlite"

mkdir -p ${builddir}
if [ ! -e "${toasterdb}" ]; then
    cp ${bootstrap}/toaster.sqlite ${toasterdb}

    # Replace /home/usersetup with the new workdir
    # This is required because toaster still has non-relocatable data in the
    # database we created during bootstrapping.
    sqlite3 ${toasterdb} "UPDATE bldcontrol_buildenvironment \
                          set sourcedir='${workdir}',builddir='${builddir}'"
fi

# oe environment setup
. ${bootstrap}/poky/oe-init-build-env ${builddir}

# run toaster and drop to an interactive shell
. ${bootstrap}/poky/bitbake/bin/toaster
exec bash -i
