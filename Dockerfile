# Copyright (C) 2015-2016 Intel Corporation
# Copyright (C) 2022 Konsulko Group
#
# SPDX-License-Identifier: GPL-2.0-only

FROM crops/yocto:ubuntu-20.04-base

USER root

ADD https://raw.githubusercontent.com/crops/extsdk-container/master/restrict_useradd.sh  \
        https://raw.githubusercontent.com/crops/extsdk-container/master/restrict_groupadd.sh \
        https://raw.githubusercontent.com/crops/extsdk-container/master/usersetup.py \
        /usr/bin/
COPY primetoaster.sh \
            toaster-launch.sh \
            toaster-entry.py \
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
    apt-get -y install python3-pip python3-venv sudo sqlite tzdata && \
    apt-get clean && \
    userdel -r yoctouser && \
    groupadd -g 70 usersetup && \
    useradd -N -m -u 70 -g 70 usersetup && \
    chmod 755 /usr/bin/primetoaster.sh \
        /usr/bin/usersetup.py \
        /usr/bin/toaster-launch.sh \
        /usr/bin/toaster-entry.py \
        /usr/bin/restrict_groupadd.sh \
        /usr/bin/restrict_useradd.sh && \
    echo "#include /etc/sudoers.usersetup" >> /etc/sudoers


# Set up a python virtual environment
RUN mkdir /opt/venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN chmod -R 0777 ${VIRTUAL_ENV}

USER usersetup
ENV LANG=en_US.UTF-8
# Install the toaster requirements.
ARG BRANCH
ARG GITREPO
RUN git clone $GITREPO --depth=1 --branch=$BRANCH /home/usersetup/poky
RUN ${VIRTUAL_ENV}/bin/activate
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install -r /home/usersetup/poky/bitbake/toaster-requirements.txt

RUN primetoaster.sh /home/usersetup /home/usersetup/poky

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/bin/toaster-entry.py"]
