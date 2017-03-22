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
# "logs into" a named container as the user (default root)
# ./login REDHAWK_DEV redhawk

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Param check, help, etc.
if [ -z ${1+x} ]; then
	echo You must supply a container name
	exit 1;
else
	if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
		echo Help: $0 CONTAINER_NAME \[USER_NAME\]
		echo - \[\] arguments are optional
		echo - USER_NAME is the username to login with \(default root\)
		exit 0
	fi
fi

CONTAINER_NAME=$1
USER_NAME=${2:-root}

# Check for the container
$DIR/container-running.sh ${CONTAINER_NAME}
case $? in
2)
	echo ${CONTAINER_NAME} does not exist
	exit 1
	;;
1)
	echo ${CONTAINER_NAME} is not running
	exit 0
	;;
*)
	echo Joining... Type \"exit\" when finished.
	docker exec -u ${USER_NAME} -it ${CONTAINER_NAME} bash
	;;
esac