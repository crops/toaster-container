#!/bin/bash

set -e

WORKDIR=$1

cd $WORKDIR

git clone git://git.yoctoproject.org/poky --depth=1 --branch=krogoth && \

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
