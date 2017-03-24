#!/bin/bash
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

# Change generic user's ID to the external user's which will re-chown
# the home directory and workspace
chown -R ${RHUSER_ID}:redhawk /home/user
usermod -u ${RHUSER_ID} user

# Set d-bus machine-id
if [ ! -e /etc/machine-id ]; then
	dbus-uuidgen > /etc/machine-id
fi

# Start d-bus
mkdir -p /var/run/dbus
dbus-daemon --system

# Run the IDE as the user in vnc
rm -f /tmp/.X*-lock
Xvnc -SecurityTypes=none ${DISPLAY} &
mutter -d ${DISPLAY} &
su -lc 'rhide --data /home/user/redhawk_workspace' user
