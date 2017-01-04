#!/bin/bash

# These variables are fully defined in runtests.sh
# Just short descripstions appear here
# what container to run. Usually crops/toaster-master
export IMAGE=crops/toaster-master
# absolute path to poky you are bisecting
# I tend to run this with poky in $(pwd)/poky
export POKYDIR=$(pwd)/poky
# which project branch to test. on a bisect, local is safest.
export POKYBRANCH=local
# vnc setup so you can watch it, if you'd like. This is optional.
# available off machine ->VNCPORT=0.0.0.0:5900
# on machine only VNCPORT=127.0.0.1:5900
# vnc password = secret
export VNCPORT=127.0.0.1:5900

# Start of bisect section
# known good commit start with
# can be branch or tag or commitish
GOOD_COMMIT=a0374e92a82e8c31964163f2eefa471bfe1eb0d4

# known bad commit to start with
# can be branch or tag or commitish
BAD_COMMIT=master

# path to runtests.sh
TEST_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# set up the bisect
cd $POKYDIR
git bisect start || exit "SAD, no couldn't start bisect"
git checkout $GOOD_COMMIT || exit "SAD, no GOOD Commit $GOOD_COMMIT"
git bisect good
git checkout $BAD_COMMIT || exit "SAD, no BAD Commit $GOOD_COMMIT"
git bisect bad

# run the bisect test
git bisect run $TEST_DIR/runtests.sh

# leave us in the last happy state. remind them toclose the bisect
echo "Remember to run git bisect reset, when finished!!!"
