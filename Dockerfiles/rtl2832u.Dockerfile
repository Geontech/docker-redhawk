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
LABEL version="2.0.5" description="REDHAWK RTL2832U -based Node"

ENV DOMAINNAME  ""
ENV RTL_NAME    ""
ENV RTL_VENDOR  ""
ENV RTL_PRODUCT ""
ENV RTL_SERIAL  ""
ENV RTL_INDEX   ""
ENV NODENAME    ""

ENTRYPOINT [\
	"/bin/bash", "-l", "-c", \
	"${SDRROOT}/dev/devices/rh/RTL2832U/nodeconfig.py" \
		"--domainname=${DOMAINNAME}" \
		"--nodename=${NODENAME}" \
		"--noinplace" \
		"--rtlname=${RTL_NAME}" \
		"--rtlvendor=${RTL_VENDOR}" \
		"--rtlproduct=${RTL_PRODUCT}" \
		"--rtlserial=${RTL_SERIAL}" \
		"--rtlindex=${RTL_INDEX}" \
	]

CMD [\
	"/bin/bash", "-l", "-c", \
	"nodeBooter", "-d", "/nodes/${NODENAME}/DeviceManager.dcd.xml" \
	]