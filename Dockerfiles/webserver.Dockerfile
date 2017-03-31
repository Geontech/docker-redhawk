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
LABEL version="2.0.5" description="REDHAWK GPP"

RUN yum install -y \
        git \
        protobuf-devel \
        protobuf-python \
        python-pip \
        python-virtualenv

WORKDIR /opt

# Update pip
RUN pip install -U pip

# Install the rest-python server
RUN git clone https://github.com/geontech/rest-python.git && \
    cd rest-python && \
    git checkout develop-2.0-pb2 && \
    cd protobuf && \
    protoc * --python_out=../rest/util_pb2 && \
    cd ../ && \
    ./setup.sh install && \
    pip install -r requirements.txt

# Mount point for end-user apps
VOLUME /opt/rest-python/apps

WORKDIR /opt/rest-python
CMD [ "/bin/bash", "-l", "-c", "./pyrest.py" ]
