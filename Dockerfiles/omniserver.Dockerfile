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

FROM redhawk/base
MAINTAINER Thomas Goodwin <btgoodwin@geontech>
LABEL version="2.0.5" description="CentOS 7 running Omni Services"

# Install pip, supervisord, and the omni* configuration.
RUN yum update -y && yum install -y python-dev curl
RUN curl https://bootstrap.pypa.io/get-pip.py | python
RUN pip install --upgrade pip && \
	pip install --upgrade supervisor && \
	mkdir -p /var/log/omniORB && \
	mkdir -p /var/log/omniEvents
ADD files/supervisord-omniserver.conf /etc/supervisor/supervisord.conf

EXPOSE 2809 11169

CMD ["/usr/bin/supervisord"]


