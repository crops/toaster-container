#!/bin/bash

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
