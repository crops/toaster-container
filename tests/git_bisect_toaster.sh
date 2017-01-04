#!/bin/bash

# so we can stop if we need to
function trap_exit {
    cd $POKYDIR
    echo
    echo "Exiting due to signal..."
    # this is messy and heavy handed as it will kill other bisects running at the
    # same time.  Unfortunately, bisect/runtests was quite incorrigible.
    ps augxww | grep "git-bisect run" | grep runtests.sh | awk '{print $2}' | \
	xargs kill   >>/dev/null 2>&1
    git bisect reset >>/dev/null 2>&1
    echo "Signal exits are messy. Do an explicit checkout of POKYDIR to return to a known state."
    exit
}
trap "trap_exit" SIGHUP SIGINT SIGTERM

function usage {
    echo "usage: $0 POKYDIR BAD_COMMIT GOOD COMMIT "
    echo "    POKYDIR - absolute path to poky you are bisecting"
    echo "    BAD_COMMIT - branch,tag, or commit that fails"
    echo "    GOOD_COMMIT - branch,tag, or commit that works"
    echo "Less commonly changed parameters can be overriden as environment variables"
    echo "runtests.sh has more information on what these mean"
    echo "    IMAGE - typically crops/toaster-master, which container to run"
    echo "    POKYDIR - absolute path to poky directory to bisect"
    echo "    POKYBRANCH - which project type to test. Typically local"
    echo ""
}

# check for usage
if [ $# != 3 ]; then
    usage
    exit
fi

# These variables are fully defined in runtests.sh
# Just short descripstions appear here
# what container to run. Usually crops/toaster-master
if [ "$IMAGE" = "" ]; then
    export IMAGE=crops/toaster-master
fi

# absolute path to poky you are bisecting
if [ -d ${1}/bitbake ]; then
    export POKYDIR=$1
else
    echo "No usable POKYDIR found..."
    usage
    exit
fi

# which project branch to test. on a bisect, local is safest
# and fastest as it has no git clones to run.
# on master, typically this can be:
# local, master, or the last official release (like morty)
if [ "$POKYBRANCH" = "" ]; then
    export POKYBRANCH=local
fi

# known bad commit to start with
# can be branch or tag or commitish
BAD_COMMIT=$2

# known good commit start with
# can be branch or tag or commitish
GOOD_COMMIT=$3


# path to runtests.sh
TEST_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# set up the bisect
cd $POKYDIR
git bisect start $BAD_COMMIT $GOOD_COMMIT || exit "SAD, couldn't start bisect"
# run the bisect test
git bisect run $TEST_DIR/runtests.sh


# leave us in the last happy state. remind them to close the bisect
echo "Remember to run git bisect reset, when finished!!!"
