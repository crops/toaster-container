#!/bin/bash

# runtests.sh
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

# Variables you might care about:
# SELENIUM_VERSION
#    This is the version of selenium that will be used for the selenium
#    container and the selenium modules installed in the virtualenv. The
#    default is 2.53.0.
#
# IMAGE
#    This is the image to be used for toaster. It should be in the same format
#    as passed to "docker run". By default, it is set to
#    "crops/toaster:latest".
#
# POKYBRANCH
#    If set, this is the branch of poky that will be used by toaster when doing
#    a build. i.e. "jethro", "krogoth", "master"
#    By default it is "master".
#
# VNCPORT
#    When set, the selenium container will be ran with a vncserver listening
#    on this port. The password for the selenium vnc server is "secret". Note,
#    you cannot of course connect to the vnc server until the selenium
#    container has finished starting.
#
# SHOW_LOGS_ON_FAILURE
#    When set, if the tests fail, the contents of toaster.log and selenium.log
#    will be output to the terminal. This is useful for when running on travis.
#
# SELENIUM_TIMEOUT
#    The amount of time to wait for elements in selenium. The default will
#    be the default for the --timeout argument to smoketests, which is 120.

set -e

function stop_containers () {
    docker kill $toastername $seleniumname >& /dev/null
}

trap fail SIGINT SIGTERM ERR
function fail () {
    set +e

    kill $(jobs -p)
    stop_containers

    echo "FAILURE: See logs in $tempdir"
    if [ "" != "$SHOW_LOGS_ON_FAILURE" ]; then
         printf "******************toaster.log*******************"
         if [ "" != "$toasterlog" ]; then
             cat $toasterlog
         fi
         printf "******************toaster.log*******************\n\n"

	 printf "******************selenium.log******************"
         if [ "" != "$seleniumlog" ]; then
             cat $seleniumlog
         fi
	 printf "******************selenium.log******************\n\n"
    fi

    exit 1
}

function start_toaster() {
    mkdir $tempdir/toasterbuild

    touch $toasterlog
    sentinel="Successful start."

    # This convoluted command will output the logfile until the sentinel is
    # found.
    bash -c "tail -n +0 -f $toasterlog | \
             { sed '/$sentinel/ q' && kill \$\$;}" &

    printf "\n\nStarting toaster...\n"
    docker run -t --rm=true --name=$toastername \
               -v $tempdir/toasterbuild:/workdir \
               $image >> $toasterlog 2>&1 &
    toasterpid=$!

    while ! grep "$sentinel" $toasterlog >& /dev/null; do
        # Check if the job exited
        if [ "$(ps -p $toasterpid -o comm=)" != "docker" ] ; then
    	    echo "ERROR: The toaster job couldn't be found."
            fail
        fi
        sleep 1
    done
}

function start_selenium() {
    touch $seleniumlog
    sentinel="Selenium Server is up and running"
    # This convoluted command will output the logfile until the sentinel is
    # found.
    bash -c "tail -n +0 -f $seleniumlog | \
             { sed '/$sentinel/ q' && kill \$\$;}" &

    printf "\n\nStarting selenium...\n"
    if [ "$VNCPORT" != "" ]; then
        docker run --rm=true -p 127.0.0.1:$VNCPORT:5900 \
                   -p 127.0.0.1:4444:4444 --name=$seleniumname \
                   --link=$toastername \
                   selenium/standalone-firefox-debug:$selenium_version \
                   >> $seleniumlog 2>&1 &
    else
        docker run --rm=true -p 127.0.0.1:4444:4444 --name=$seleniumname \
                   --link=$toastername \
                   selenium/standalone-firefox:$selenium_version \
                   >> $seleniumlog 2>&1 &
    fi
    seleniumpid=$!

    while ! grep "$sentinel" $seleniumlog >& /dev/null; do
        # Check if the job exited
        if [ "$(ps -p $seleniumpid -o comm=)" != "docker" ] ; then
    	    echo "ERROR: The selenium job couldn't be found."
            fail
        fi
        sleep 1
    done
}

tempdir=$(mktemp -d --suffix toastertest --tmpdir)
echo "Logs in $tempdir"

id=$(uuidgen)
toastername=toasterserver-$id
seleniumname=seleniumserver-$id

toasterlog=$tempdir/toaster.log
seleniumlog=$tempdir/selenium.log

if [ "" != "$IMAGE" ]; then
    image="$IMAGE"
else
    image="crops/toaster:latest"
fi

if [ "" != "$SELENIUM_VERSION" ]; then
    selenium_version="$SELENIUM_VERSION"
else
    selenium_version=2.53.0
fi

if [ "" != "$POKYBRANCH" ]; then
    pokybranch_arg="--pokybranch=$POKYBRANCH"
fi

if [ "" != "$SELENIUM_TIMEOUT" ]; then
    timeout_arg="--timeout=$SELENIUM_TIMEOUT"
fi


# Create a virtualenv that contains the modules needed by smoketests.py
virtualenv $tempdir/selenium
. $tempdir/selenium/bin/activate
pip install selenium==$selenium_version


# Run the containers
start_toaster
start_selenium


printf "\n\nRunning tests...\n"
./smoketests.py --toaster_url="$toastername:8000" \
                $timeout_arg \
                $pokybranch_arg
./checkartifacts.sh $tempdir/toasterbuild/build-toaster-2
echo "TESTS PASSED!"


stop_containers
rm $tempdir -rf
