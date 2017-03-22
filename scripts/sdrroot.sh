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
# Creates or removes SDRROOT volumes.  Arguments:
#
# 1) create|delete
# 2) VOLUME_NAME

if [ -z ${1+x} ]; then
	echo You must state either create or delete
	exit 1
else
	if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
		echo Help: $0 create\|delete VOLUME_NAME
		echo - VOLUME_NAME is the name to use for the volume
		exit 0
	fi
fi
if [ -z ${2+x} ]; then
	echo You must provide a \(unique\) volume name
	exit 1
fi
COMMAND=${1}
VOLUME_NAME=${2}

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


if [[ $COMMAND == "create" ]]; then
	$DIR/volume-exists.sh ${VOLUME_NAME}
	if [ $? -eq 0 ]; then
		echo The volume ${VOLUME_NAME} already exists
		exit 1
	else
		echo Creating... $(docker volume create ${VOLUME_NAME})
		
	fi
elif [[ $COMMAND == "delete" ]]; then
	if [ $? -eq 1 ]; then
		echo The volume ${VOLUME_NAME} does not exist
	else
		echo Removing... $(docker volume rm ${VOLUME_NAME})
	fi;
else
	echo Unknown command: ${COMMAND}
	exit 1
fi