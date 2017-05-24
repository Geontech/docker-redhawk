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

FROM centos:7

ENV RH_VERSION=2.0.5

LABEL name="REDHAWK SDR Base Image" \
    license="GPLv3" \
    description="REDHAWK SDR repository, omni services, and EPEL)" \
    maintainer="Thomas Goodwin <btgoodwin@geontech.com>" \
    version="${RH_VERSION}" \
    vendor="Geon Technologies, LLC"

# Update, epel, etc. and omni services as well as upgraded pyparsing
RUN yum update -y && \
    yum install -y \
    python-dev \
    curl \
    wget \
    epel-release \
    http://cbs.centos.org/kojifiles/packages/pyparsing/2.0.3/1.el7/noarch/pyparsing-2.0.3-1.el7.noarch.rpm

# Add Supervisord and default configuration
RUN curl https://bootstrap.pypa.io/get-pip.py | python
RUN pip install --upgrade pip && \
    pip install --upgrade supervisor && \
    mkdir -p /etc/supervisor.d && \
    mkdir -p /var/log/supervisord
ADD files/supervisord.conf /etc/supervisor/supervisord.conf

# Load the REDHAWK repo
ADD files/repo-installer.sh /opt
WORKDIR /opt
RUN bash ./repo-installer.sh && rm ./repo-installer.sh

# Install omni services and add event service to config
RUN yum update -y && yum install -y omniORB-servers omniEvents-server && \
	echo "InitRef = EventService=corbaloc::127.0.0.1:11169/omniEvents" >> /etc/omniORB.cfg

# IP address for omni services and an auto-configure script
ENV OMNISERVICEIP 127.0.0.1
ADD files/omnicfg-updater.sh /root/omnicfg-updater.sh
RUN chmod u+x /root/omnicfg-updater.sh && echo "/root/omnicfg-updater.sh" | tee -a /root/.bash_profile

WORKDIR /root

CMD ["/bin/bash", "-l"]
