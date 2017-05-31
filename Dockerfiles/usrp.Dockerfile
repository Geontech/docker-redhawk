# This file is protected by Copyright. Please refer to the COPYRIGHT file
# distributed with this source distribution.
#
# This file is part of Geon's Docker REDHAWK.
#
# Docker REDHAWK is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Docker REDHAWK is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.
#

FROM geontech/redhawk-runtime:2.0.5
LABEL name="REDHAWK SDR USRP_UHD Device" \
    description="REDHAWK USRP_UHD w/ updated UHD driver version (3.10)" \
    maintainer="Thomas Goodwin <btgoodwin@geontech.com>"

# Compile UHD from source
RUN yum install -y \
        redhawk-sdrroot-dev-mgr \
        autoconf \
        automake \
        cmake \
        doxygen \
        python-pip \
        git \
        g++ \
        boost-devel \
        libusb1-devel \
        gpsd-devel \
        python-mako \
        python-requests \
        python-docutils \
        gcc \
        gcc-c++ \
        e2fsprogs-devel \
        rpm-build && \
    \
    git clone git://github.com/EttusResearch/uhd.git && \
    mkdir -p uhd/host/build && \
    pushd uhd/host/build && \
    git checkout release_003_010_001_001 && \
    cmake ../ && \
    make && \
    make test && \
    make install && \
    ldconfig && \
    cpack ../ && \
    \
    yum autoremove -y \
        autoconf \
        automake \
        cmake \
        doxygen \
        python-pip \
        git \
        g++ \
        boost-devel \
        libusb1-devel \
        gpsd-devel \
        gcc \
        gcc-c++ \
        e2fsprogs-devel \
        rpm-build && \
    \
    yum localinstall -y uhd*.rpm && \
    yum clean all -y && \
    popd && \
    rm -rf uhd && \
    ldconfig

# Compile USRP_UHD from source
RUN yum install -y \
        redhawk-devel \
        autoconf \
        automake \
        git && \
    source /etc/profile.d/redhawk.sh && \
    source /etc/profile.d/redhawk-sdrroot.sh && \
    git clone git://github.com/RedhawkSDR/USRP_UHD.git && \
    pushd USRP_UHD && \
    git checkout tags/4.0.1 && \
    ./build.sh && \
    ./build.sh install && \
    popd && \
    rm -rf USRP_UHD && \
    \
    yum autoremove -y \
        redhawk-devel \
        autoconf \
        automake && \
    yum clean all -y && \
    /usr/local/lib64/uhd/utils/uhd_images_downloader.py


ENV DOMAINNAME      ""
ENV NODENAME        ""
ENV USRP_IP_ADDRESS ""
ENV USRP_TYPE       ""
ENV USRP_NAME       ""
ENV USRP_SERIAL     ""

# Add script for configuring the node
ADD files/usrp-node-init.sh /root/usrp-node-init.sh
RUN chmod u+x /root/usrp-node-init.sh && \
    echo "/root/usrp-node-init.sh" | tee -a /root/.bashrc

# USRP Supervisord script and exit script
ADD files/supervisord-usrp.conf /etc/supervisor.d/usrp.conf
ADD files/kill_supervisor.py /usr/bin/kill_supervisor.py
RUN chmod u+x /usr/bin/kill_supervisor.py

CMD ["/usr/bin/supervisord"]
