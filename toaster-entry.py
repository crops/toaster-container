#!/usr/bin/env python
#
# This script is to present arguments to the user of the container and then
# chuck them over to the scripts that actually do the work.
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
import argparse
import os

parser = argparse.ArgumentParser(epilog="NOTE: The --workdir is the path as "
                                        "seen inside of the container. So if "
                                        "-v /foo:/bar was passed to docker, "
                                        "--workdir should be set to /bar.")

parser.add_argument("--workdir", default='/workdir',
                    help="Directory to use for the toasterbuild")
parser.add_argument("--local", action="store_true",
                    help="Run Toaster from the poky in the workdir instead of the default one in the container."
                    "This option is intended for developers of Toaster itself and is not supported for end users.")

args = parser.parse_args()

cmd = ("usersetup.py --username=toasteruser --workdir={} "
       "toaster-launch.sh {}")
cmd = cmd.format(args.workdir, args.workdir).split()

if args.local:
    cmd.append("LOCAL")
os.execvp(cmd[0], cmd)
