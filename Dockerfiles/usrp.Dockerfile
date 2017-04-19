# This file is protected by Copyright. Please refer to the COPYRIGHT file
# distributed with this source distribution.
#
# This file is part of Docker REDHAWK.
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

FROM redhawk/runtime
MAINTAINER Thomas Goodwin <btgoodwin@geontech>
LABEL version="2.0.5" description="REDHAWK USRP_UHD -based Node w/ up-to-date UHD"

# Remove old UHD and USRP_UHD
RUN yum update -y && \
    yum install -y \
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
        rpm-build   

# compile the up-to-date verison of UHD

RUN git clone git://github.com/EttusResearch/uhd.git && \
    mkdir -p uhd/host/build && \
    cd uhd/host/build && \
    cmake ../ && \
    make && \
    make test && \
    make install && \
    ldconfig && \
    cpack ../

# compile up-to-date version of USRP_UHD

RUN cd uhd/host/build/ && \
    yum localinstall -y uhd*.rpm && \
    ldconfig 

RUN source /etc/profile.d/redhawk.sh && \
    source /etc/profile.d/redhawk-sdrroot.sh && \
    git clone git://github.com/RedhawkSDR/USRP_UHD.git && \
    cd USRP_UHD && \
    git checkout tags/4.0.1 && \
    ./build.sh && \
    ./build.sh install


ENV DOMAINNAME      ""
ENV NODENAME        ""
ENV USRP_IP_ADDRESS ""
ENV USRP_TYPE       ""
ENV USRP_NAME       ""
ENV USRP_SERIAL     ""

# Add script for configuring the node
ADD files/usrp-node-init.sh /root/usrp-node-init.sh
RUN echo "/root/usrp-node-init.sh" | tee -a /root/.bashrc

# Add the nodeBooter script
ADD files/nodeBooter.sh /root/nodeBooter.sh

# Add call to uhd_images_downloader to pick up the latest images both now and
# update them on container start.
RUN /usr/local/lib64/uhd/utils/uhd_images_downloader.py && \
    echo "/usr/local/lib64/uhd/utils/uhd_images_downloader.py" | tee -a /root/.bashrc

# Call uhd_find_devices then run the nodeBooter wrapper
CMD ["/bin/bash", "-c", "uhd_find_devices && /root/nodeBooter.sh -d /nodes/$NODENAME/DeviceManager.dcd.xml"]
