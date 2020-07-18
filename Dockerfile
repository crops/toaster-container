# Copyright (C) 2015-2016 Intel Corporation
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

FROM crops/yocto:ubuntu-18.04-base

USER root

ADD https://raw.githubusercontent.com/crops/extsdk-container/master/restrict_useradd.sh  \
        https://raw.githubusercontent.com/crops/extsdk-container/master/restrict_groupadd.sh \
        https://raw.githubusercontent.com/crops/extsdk-container/master/usersetup.py \
        /usr/bin/
COPY primetoaster.sh \
            toaster-launch.sh \
            toaster-entry.py \
            pipinstall.sh \
        /usr/bin/
COPY sudoers.usersetup /etc/

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
# For ubuntu, do not use dash.
RUN which dash &> /dev/null && (\
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash) || \
    echo "Skipping dash reconfigure (not applicable)"

# We remove the user because we add a new one of our own.
# The usersetup user is solely for adding a new user that has the same uid,
# as the workspace. 70 is an arbitrary *low* unused uid on debian.
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y update && \
    apt-get -y install python3-pip sudo sqlite tzdata && \
    apt-get clean && \
    userdel -r yoctouser && \
    groupadd -g 70 usersetup && \
    useradd -N -m -u 70 -g 70 usersetup && \
    chmod 755 /usr/bin/primetoaster.sh \
        /usr/bin/usersetup.py \
        /usr/bin/toaster-launch.sh \
        /usr/bin/toaster-entry.py \
        /usr/bin/pipinstall.sh \
        /usr/bin/restrict_groupadd.sh \
        /usr/bin/restrict_useradd.sh && \
    echo "#include /etc/sudoers.usersetup" >> /etc/sudoers

# Install the toaster requirements.
ARG BRANCH
ARG GITREPO
RUN git clone $GITREPO --depth=1 --branch=$BRANCH /home/usersetup/poky && \
    pipinstall.sh /home/usersetup/poky/bitbake

USER usersetup
ENV LANG=en_US.UTF-8
RUN primetoaster.sh /home/usersetup /home/usersetup/poky

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/bin/toaster-entry.py"]
