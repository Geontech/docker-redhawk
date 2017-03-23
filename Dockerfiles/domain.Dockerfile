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
LABEL version="2.0.5" description="REDHAWK Domain"

RUN yum install -y \
	redhawk-basic-components
	# rh.agc \
	# rh.AmFmPmBasebandDemod \
	# rh.autocorrelate \
	# rh.blueFileLib \
	# rh.DataConverter \
	# rh.dsp \
	# rh.fastfilter \
	# rh.fcalc \
	# rh.fftlib \
	# rh.FileReader \
	# rh.FileWriter \
	# rh.HardLimit \
	# rh.psd \
	# rh.psk_soft \
	# rh.RBDSDecoder \
	# rh.SigGen \
	# rh.SinkDDS \
	# rh.sinksocket \
	# rh.SourceSDDS \
	# rh.sourcesocket \
	# rh.TuneFilterDecimate

ENV DOMAINNAME ""

VOLUME /var/redhawk/sdr

CMD [\
	"/bin/bash", "-l", "-c", \
	"nodeBooter -D --domainname ${DOMAINNAME}" \
	]


