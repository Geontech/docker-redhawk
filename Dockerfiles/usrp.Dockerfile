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
RUN yum remove -y \
		rh.USRP_UHD* \
		uhd-* \
		uhd.x86_64 && \
	yum install -y \
		cmake \
		doxygen \
		python-pip \
		git
RUN pip install --upgarde pip && \
    pip install --upgrade mako && \
    pip install --upgrade requests

# compile the up-to-date verison of UHD
RUN git clone git://github.com/EttusResearch/uhd.git && \
	mkdir -p uhd/host/build && \
	cd uhd/host/build && \
	cmake ../ && \
	make test && \
	make install && \
	cd ../../../ && \
	rm -rf uhd && \
	ldconfig

# compile up-to-date version of USRP_UHD
RUN git clone git://github.com/RedhawkSDR/USRP_UHD.git && \
	cd USRP_UHD && \
	git checkout tags/4.0.1 && \
	./build.sh && \
	./build.sh install && \
	cd ../ \
	rm -rf USRP_UHD


ENV DOMAINNAME      ""
ENV USRP_IP_ADDRESS ""
ENV USRP_NAME       ""
ENV USRP_SERIAL     ""
ENV NODENAME        ""

ENTRYPOINT [\
	"/bin/bash", "-l", "-c", \
	"${SDRROOT}/dev/devices/rh/USRP_UHD/nodeconfig.py --domainname=${DOMAINNAME} --nodename=${NODENAME} --noinplace --usrpproduct=${USRP_IP_ADDRESS} --usrpname=${USRP_NAME} --usrpserial=${USRP_SERIAL}" \
	]

CMD [\
	"/bin/bash", "-l", "-c", \
	"nodeBooter -d /nodes/${NODENAME}/DeviceManager.dcd.xml" \
	]