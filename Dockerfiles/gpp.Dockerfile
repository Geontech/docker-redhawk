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

ENV DOMAINNAME ""
ENV NODENAME   ""
ENV GPPNAME    ""

ADD files/gpp-node-init.sh /root/gpp-node-init.sh
RUN echo "/root/gpp-node-init.sh" | tee -a /root/.bashrc

CMD [\
	"/bin/bash", "-l", "-c", \
	"nodeBooter -d /nodes/${NODENAME}/DeviceManager.dcd.xml &> /opt/nodeBooter.log" \
	]