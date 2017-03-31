#!/bin/bash -l
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
set -e

handler () {
	echo "Trapped SIGINT" >> $LOG
	kill -SIGINT $PID
	echo "Kill sent, waiting..."
	sleep 5
	echo "Delay finished" >> $LOG
}

LOG=/var/log/nodeBooter.log

echo "Executing: nodeBooter $*" > $LOG
jobs &> /dev/null
nodeBooter $* >> $LOG 2>&1 &
sleep 10

nbjobs="$(jobs -n)"
if [ -n "$nbjobs" ]; then
	PID=$!
else
	echo "ERROR: Exiting..." >> $LOG
	exit 1
fi

echo "Started process ID: ${PID}" >> $LOG


# Trap and wait for the handler
trap handler SIGINT SIGTERM SIGKILL SIGHUP EXIT
wait $PID