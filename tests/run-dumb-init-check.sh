#!/bin/bash

# run-dumb-init-check.sh
#
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

# This verifies that dumb-init is running as the correct user and is running
# what we expected.
container="$1"

username="usersetup"
username_width=${#username}
required="^1 $username /usr/bin/dumb-init"

# Use bash -c, because otherwise you must specify an absolute path to ps,
# because $PATH would not be set.
actual=`docker exec $container bash -c "ps -w -w h -C dumb-init -o pid:1,user:$username_width,args"`
# just make sure that dumbinit is running as pid 1.
# Limiting the check to this makes the test insensitive to
# flags/options like --local
if [ "$actual" =~ "$required" ]; then
    printf "required dumb-init not found\n"
    printf "required:\n%s\n" "$required"
    printf "actual:\n%s\n" "$actual"
    printf "all:\n"
    docker exec $container bash -c "ps -w -w -A -o pid,user:$username_width,args"
    exit 1
fi
