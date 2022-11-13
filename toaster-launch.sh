#!/bin/bash -i
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
workdir="${1}"
uselocal="${2}"

# If it doesn't already exist copy the toaster database from the container
# so that it doesn't have to be created again
bootstrap="/home/usersetup"
builddir="${workdir}/build"
# toaster moved the toaster.sqlite db from $builddir to $toaster_dir after morty
if grep TOASTER_DIR $bootstrap/poky/bitbake/bin/toaster | grep -q pwd; then
    toasterdb="${builddir}/toaster.sqlite"
else
    toasterdb="${workdir}/toaster.sqlite"
fi

if  [ "${uselocal}" = "LOCAL" ]; then
    if [ ! -e ${workdir}/poky ]; then
        echo -e "The LOCAL mode assumes that there is a usable poky in the " \
                "workdir you passed in.\n" \
                "Current container view of workdir is ${workdir}"
        exit 1
    fi
    # in local mode we reset bootstrap to be workdir and just run what's there
    bootstrap=${workdir}
fi

mkdir -p ${builddir}
# don't copy over the database if it's already there or if we are in local mode
if [ ! -e "${toasterdb}" ] && [ "${uselocal}" != "LOCAL" ] ; then
    cp ${bootstrap}/toaster.sqlite ${toasterdb}

    # Replace /home/usersetup with the new workdir
    # This is required because toaster still has non-relocatable data in the
    # database we created during bootstrapping.
    sqlite3 ${toasterdb} "UPDATE bldcontrol_buildenvironment \
                          set sourcedir='${workdir}',builddir='${builddir}'"
fi

# activate python3 virtual environment
VIRTUAL_ENV=/opt/venv
PATH="$VIRTUAL_ENV/bin:$PATH"
${VIRTUAL_ENV}/bin/activate

# oe environment setup
. ${bootstrap}/poky/oe-init-build-env ${builddir}

# Run toaster and drop to an interactive shell.
# Note if the server listens on localhost in the container, it evidently
# can't be reached even with iptables without "route_localnet" enabled.
. ${bootstrap}/poky/bitbake/bin/toaster start webport="0.0.0.0:8000"

bash -i
