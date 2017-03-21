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
MAINTAINER Thomas Goodwin <btgoodwin@geontech>
LABEL version="2.0.5" description="CentOS 7 with REDHAWK repo and omni services configuration"


# Update, load EPEL, make a repo directory for REDHAWK
RUN yum update -y && \
    yum install -y \
    	wget \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Load the REDHAWK repo
ADD files/repo-installer.sh /opt
WORKDIR /opt
RUN RH_VERSION=2.0.5 /opt/repo-installer.sh

# Install omni services and add event service to config
RUN yum update -y && yum install -y omniORB-servers omniEvents-server && \
	echo "InitRef = EventService=corbaloc::127.0.0.1:11169/omniEvents" >> /etc/omniORB.cfg

# IP address for omni services and an auto-configure script
ENV OMNISERVICEIP 127.0.0.1
ADD files/omnicfg-updater.sh /root/omnicfg-updater.sh
RUN echo "/root/omnicfg-updater.sh" | tee -a /root/.bashrc | tee -a /root/.bash_profile

CMD ["/bin/bash", "-l"]


