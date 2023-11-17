#!/bin/bash

# runtests.sh
#
# Copyright (C) 2016-2020 Intel Corporation
# Copyright (C) 2022 Konsulko Group
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Variables you might care about:
# SELENIUM_VERSION
#    This is the version of selenium that will be used for the selenium
#    container and the selenium modules installed in the virtualenv. The
#    default is 4.15.0.
#
# IMAGE
#    This is the image to be used for toaster. It should be in the same format
#    as passed to "docker run". By default, it is set to
#    "crops/toaster:latest".
#
# POKYBRANCH
#    If set, this is the branch of poky that will be used by toaster when doing
#    a build. i.e. "dunfell", "hardknott, "honister", "master"
#    By default it is "master".
#
# TOASTER_IP
#    When set, the toaster container will be launch with this ip addr, e.g
#    TOASTER_IP=0.0.0.0
#
# TOASTER_PORT
#    When set, the toaster container will be launch with this port, e.g
#    TOASTER_PORT=18000:8000
#
# VNCPORT
#    When set, the selenium container will be run with a vncserver listening
#    on this port. The password for the selenium vnc server is "secret". Note,
#    you cannot, of course, connect to the vnc server until the selenium
#    container has finished starting. If you would like to be able to access the
#    vnc server from a different host, explicitly bind to 0.0.0.0:<portnum>
#    e.g. VNCPORT=0.0.0.0:6900 and then you can connect to the server from a
#    different host as "xtightvnc headless.mycomp.com:6900"
#
# SHOW_LOGS_ON_FAILURE
#    When set, if the tests fail, the contents of toaster.log and selenium.log
#    will be output to the terminal. This is useful for when running on travis.
#
# SELENIUM_TIMEOUT
#    The amount of time to wait for elements in selenium. The default will
#    be the default for the --timeout argument to smoketests, which is 120.
#
# POKYDIR
#    If this is set, the dir is used as the poky and the toaster container
#    is run in --local mode.  This is intended to allow you to run the test
#    on the local checkout of poky you are working on.

set -e

function stop_containers () {
    docker kill $toastername $seleniumname >& /dev/null

    # Since it appears that sometimes docker will not delete the container
    # even though --rm=true is on the "docker run" command line, also manually
    # delete the container.
    if docker ps -a | grep -q $toastername; then
        docker rm $toastername >& /dev/null
    fi
    if docker ps -a | grep -q $seleniumname; then
        docker rm $seleniumname >& /dev/null
    fi
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
               -p ${toaster_ip}:${toaster_port} \
               ${poky_bind} \
               ${image} ${local_arg} >> $toasterlog 2>&1 &
    toasterpid=$!

    while ! grep "$sentinel" $toasterlog >& /dev/null; do
        # Check if the job exited
	comm="$(ps -p $toasterpid -o comm=)"
        if [ ${comm} != "docker" -a ${comm} != "docker-current" ] ; then
            echo "ERROR: The toaster job couldn't be found."
            fail
        fi
        sleep 1
    done
}

function start_selenium() {
    touch $seleniumlog
    sentinel="Started Selenium Standalone"
    # This convoluted command will output the logfile until the sentinel is
    # found.
    bash -c "tail -n +0 -f $seleniumlog | \
             { sed '/$sentinel/ q' && kill \$\$;}" &

    printf "\n\nStarting selenium...\n"
    if [ "$VNCPORT" != "" ]; then
        # default to loclahost visibility only, unless specified.
        HOST_VNCBINDING="127.0.0.1:$VNCPORT"
        if   echo $VNCPORT | grep -q ":"; then
            HOST_VNCBINDING="$VNCPORT"
        fi
        docker run -t --rm -p $HOST_VNCBINDING:5900 \
                   -p 127.0.0.1:4444:4444 --name=$seleniumname \
                   --link=$toastername \
                   selenium/standalone-firefox-debug:$selenium_version \
                   >> $seleniumlog 2>&1 &
    else
        docker run -t --rm -p 127.0.0.1:4444:4444 --name=$seleniumname \
                   --link=$toastername \
                   selenium/standalone-firefox:$selenium_version \
                   >> $seleniumlog 2>&1 &
    fi
    seleniumpid=$!

    while ! grep "$sentinel" $seleniumlog >& /dev/null; do
        # Check if the job exited
	comm=$(ps -p $seleniumpid -o comm=)
        if [ ${comm} != "docker" -a ${comm} != "docker-current" ] ; then
            echo "ERROR: The selenium job couldn't be found."
            fail
        fi
        sleep 1
    done
}


id=$(uuidgen)
toastername=toasterserver-$id
seleniumname=seleniumserver-$id


if [ "" != "$IMAGE" ]; then
    image="$IMAGE"
else
    image="crops/toaster:latest"
fi

if [ "" != "$SELENIUM_VERSION" ]; then
    selenium_version="$SELENIUM_VERSION"
else
    selenium_version=4.15.0
fi

if [ "" != "$TOASTER_IP" ]; then
    toaster_ip="$TOASTER_IP"
else
    toaster_ip=0.0.0.0
fi

if [ "" != "$TOASTER_PORT" ]; then
    toaster_port="$TOASTER_PORT"
else
    toaster_port=18000:8000
fi

if [ "" != "$POKYBRANCH" ]; then
    pokybranch_arg="--pokybranch=$POKYBRANCH"
fi

if [ "" != "$SELENIUM_TIMEOUT" ]; then
    timeout_arg="--timeout=$SELENIUM_TIMEOUT"
fi

if [ "" != "$POKYDIR" ]; then
    local_arg="--local"
    poky_bind="-v $POKYDIR:/workdir/poky"
fi

tempdir=$(mktemp -d --suffix toastertest --tmpdir)
echo "Logs in $tempdir"

toasterlog=$tempdir/toaster.log
seleniumlog=$tempdir/selenium.log
toaster_ui_log=$tempdir/toasterbuild/build-toaster-2/toaster_ui.log


# Create a virtualenv that contains the modules needed by smoketests.py
virtualenv $tempdir/selenium
. $tempdir/selenium/bin/activate
pip install selenium==$selenium_version


# Run the containers
start_toaster
start_selenium


printf "\n\nRunning tests...\n"
if [ -n "$BASH_SOURCE" ]; then
    THIS_SCRIPT=$BASH_SOURCE
elif [ -n "$ZSH_NAME" ]; then
    THIS_SCRIPT=$0
else
    THIS_SCRIPT="$(pwd)/runtests.sh"
fi
SCRIPT_DIR=$(dirname "$THIS_SCRIPT")
SCRIPT_DIR=$(readlink -f "$SCRIPT_DIR")

${SCRIPT_DIR}/smoketests.py --toaster_url="http://$toastername:8000/" \
                $timeout_arg \
                $pokybranch_arg
echo "smoketests PASSED!"

${SCRIPT_DIR}/checkartifacts.sh $tempdir/toasterbuild/build-toaster-2
echo "checkartifacts PASSED!"

${SCRIPT_DIR}/run-dumb-init-check.sh $toastername
echo "run-dumb-init-check PASSED!"

if [[ "" == "$POKYDIR" ]]; then
    # these tests only make sense if we are running the primed poky not a
    # local one
    grep -q "No migrations to apply" $toasterlog
    echo "no migration priming PASSED"

    if grep -q "INFO Fetching layers" $toasterlog; then
        fail
    fi
    echo "layerindex priming PASSED"
fi
echo "ALL TESTS PASSED!"; exit 0

function fail () {
set +ex

kill $(jobs -p)
stop_containers

echo "FAILURE: See logs in $tempdir"
if [ "" != "$SHOW_LOGS_ON_FAILURE" ]; then
     printf "******************toaster.log*******************\n\n"
     if [ "" != "$toasterlog" ]; then
	 cat $toasterlog
     fi
     printf "******************toaster.log*******************\n\n"

     printf "******************toaster_ui.log*******************\n"
     if [ "" != "$toaster_ui_log" ]; then
	 cat $toaster_ui_log
     fi
     printf "******************toaster_ui.log*******************\n\n"

     printf "******************selenium.log******************\n"
     if [ "" != "$seleniumlog" ]; then
	 cat $seleniumlog
     fi
     printf "******************selenium.log******************\n\n"

     printf "******************screenshot.hex******************\n"
     printf "*************Run 'xxd -r' to reverse**************\n"
     xxd screenshot.png
     printf "******************screenshot.hex******************\n\n"
fi

exit 1
}
trap fail SIGINT SIGTERM ERR

function cleanup()
{
printf "\n\nStopping containers...\n"
stop_containers

printf "\n\nRemoving temporary directory...\n"
time rm -rf $tempdir

echo $(ps -a)
}
trap cleanup EXIT
