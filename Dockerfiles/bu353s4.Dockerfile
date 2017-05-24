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
LABEL name="Geon Technology's BU353S4 GPS Device" \
    description="Geon's BU353S4" \
    maintainer="Thomas Goodwin <btgoodwin@geontech.com>"

RUN yum update -y && \
	yum install -y \
		redhawk-devel \
		libusb1-devel \
        autoconf \
        automake \
        git \
        unzip

# Download nmealib and bu353s4, compile each
RUN wget http://downloads.sourceforge.net/project/nmea/NmeaLib/nmea-0.5.x/nmealib-0.5.3.zip && \
	unzip nmealib-0.5.3.zip && \
	pushd nmealib && \
	make && cp -r lib include /usr/local && \
	popd && rm -rf nmealib nmealib-0.5.3.zip && \
	git clone git://github.com/GeonTech/BU353S4.git && \
	pushd BU353S4 && \
	source /etc/profile.d/redhawk.sh && \
	source /etc/profile.d/redhawk-sdrroot.sh && \
	./build.sh && ./build.sh install && \
	popd && rm -rf BU353S4

ENV DOMAINNAME ""
ENV GPS_PORT   ""
ENV NODENAME   "" 

# Add the node configuration file
ADD files/bu353s4-nodeconfig.py /root/nodeconfig.py
RUN chmod a+x /root/nodeconfig.py && \
	mv /root/nodeconfig.py /var/redhawk/sdr/dev/devices/BU353S4

# Add script for configuring the node
ADD files/bu353s4-node-init.sh /root/bu353s4-node-init.sh
RUN chmod u+x /root/bu353s4-node-init.sh && echo "/root/bu353s4-node-init.sh" | tee -a /root/.bashrc

# RTL2832U Supervisord script
ADD files/supervisord-bu353s4.conf /etc/supervisor.d/bu353s4.conf
CMD ["/usr/bin/supervisord"]
