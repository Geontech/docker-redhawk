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

FROM redhawk/runtime:2.0.5
LABEL name="REDHAWK SDR RTL2832U Device" \
    description="REDHAWK RTL2832U" \
    maintainer="Thomas Goodwin <btgoodwin@geontech.com>"

RUN yum update -y && \
	yum install -y rh.RTL2832U

ENV DOMAINNAME  ""
ENV RTL_NAME    ""
ENV RTL_VENDOR  ""
ENV RTL_PRODUCT ""
ENV RTL_SERIAL  ""
ENV RTL_INDEX   ""
ENV NODENAME    "" 

# Add script for configuring the node
ADD files/rtl2832u-node-init.sh /root/rtl2832u-node-init.sh
RUN chmod u+x /root/rtl2832u-node-init.sh && echo "/root/rtl2832u-node-init.sh" | tee -a /root/.bashrc

# RTL2832U Supervisord script
ADD files/supervisord-rtl2832u.conf /etc/supervisor.d/rtl2832u.conf
CMD ["/usr/bin/supervisord"]
