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

IMAGE_NAME=redhawk/domain

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


# Try to detect the omniserver
OMNISERVER="$($DIR/omniserver-ip.sh)"

# Prints the status for all containers inheriting from redhawk/domain
function print_status() {
	docker ps -a \
		--filter="ancestor=${IMAGE_NAME}"\
		--format="table {{.Names}}\t{{.Mounts}}\t{{.Networks}}\t{{.Status}}"
}

# Prints command usage information
function usage () {
	cat <<EOF

Usage: $0 start|stop
	[-d|--domain  DOMAIN_NAME]    Domain Name, default is REDHAWK_DEV
	[-s|--sdrroot SDRROOT_VOLUME] SDRROOT Volume Name
	[-o|--omni    OMNISERVER]     IP to the OmniServer 
	                              (detected: ${OMNISERVER})
	[-p|--print]                  Just print resolved settings

Examples:
	Start or stop a domain:
		$0 start|stop --domain REDHAWK_TEST2

	Status of all locally-running ${IMAGE_NAME} instances:
		$0

EOF
}

if [ -z ${1+x} ]; then
	print_status
	exit 0
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		start|stop)
			if ! [ -z ${COMMAND+x} ]; then
				usage
				echo ERROR: The start and stop commands are mutually exclusive.
				exit 1
			fi
			COMMAND="$1"
			;;
		-d|--domain)
			DOMAIN_NAME="$2"
			shift
			;;
		-s|--sdrroot)
			SDRROOT_VOLUME="$2"
			shift
			;;
		-o|--omni)
			OMNISERVER="$2"
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		-p|--print)
			JUST_PRINT=YES
			;;
		*)
			echo ERROR: Undefined option: $1 $2
			exit 1
			;;
	esac
	shift # past argument
done


if [ -z ${COMMAND+x} ]; then
	usage
	echo ERROR: No command specified \(start or stop\)
	exit 1
fi
if [[ $OMNISERVER == "" ]]; then
	usage
	echo ERROR: No omniserver running or OmniORB Server IP specified
	exit 1
fi

# Default Domain name
DOMAIN_NAME=${DOMAIN_NAME:-REDHAWK_DEV}

# "Just print"
if ! [ -z ${JUST_PRINT+x} ]; then
	cat <<EOF
Resolved Settings:
	COMMAND:        ${COMMAND}
	DOMAIN_NAME:    ${DOMAIN_NAME}
	SDRROOT_VOLUME: ${SDRROOT_VOLUME:-In Container}
	OMNISERVER:     ${OMNISERVER}
EOF
	exit 0
fi

# Default SDRROOT_VOLUME and volume command
# Q) Why uuidgen for SDRROOT_VOLUME default?
# A) Almost no way it'll ever be true, so sdrroot-cmd will be empty.
SDRROOT_VOLUME=${SDRROOT_VOLUME:-$(uuidgen)}
SDRROOT_CMD="$($DIR/sdrroot-cmd.sh $SDRROOT_VOLUME)"


# Check if the image is installed yet, if not, build it.
$DIR/image-exists.sh ${IMAGE_NAME}
if [ $? -gt 0 ]; then
	echo "${IMAGE_NAME} was not built yet, building now"
	make -C $DIR/..  ${IMAGE_NAME} || { \
		echo Failed to build ${IMAGE_NAME}; exit 1;
	}
fi

# Container name is the domain name
CONTAINER_NAME=${DOMAIN_NAME}

# Check if a domain is already running in that name.
if [[ $COMMAND == "start" ]]; then
	$DIR/container-running.sh ${CONTAINER_NAME}
	case $? in
		1)
			echo Starting...$(docker start ${CONTAINER_NAME})
			exit 0;
			;;
		0)
			echo ${IMAGE_NAME} ${CONTAINER_NAME} is already running
			exit 0;
			;;
		*)
			# Does not exist (expected), create it.
			# Compare Omni server IPs
			LOCAL_OMNI="$($DIR/omniserver-ip.sh)"
			if [[ ${OMNISERVER} == ${LOCAL_OMNI} ]]; then
				OMNISERVER_NAME=omniserver
				echo Connecting to local omniserver: $OMNISERVER
				docker run --rm -d \
					-e DOMAINNAME=${CONTAINER_NAME} \
					-e OMNISERVICEIP=${OMNISERVER} \
					${SDRROOT_CMD} \
					--link ${OMNISERVER_NAME} \
					--name ${CONTAINER_NAME} \
					${IMAGE_NAME} &> /dev/null
			else
				# IP is provided, start domain with service IP
				echo Connecting to remote omniserver: $OMNISERVER
				docker run --rm -d \
					-e DOMAINNAME=${CONTAINER_NAME} \
					-e OMNISERVICEIP=${OMNISERVER} \
					${SDRROOT_CMD} \
					--name ${CONTAINER_NAME} \
					${IMAGE_NAME} &> /dev/null
			fi

			# Verify it is running
			sleep 5
			$DIR/container-running.sh ${CONTAINER_NAME}
			if [ $? -gt 0 ]; then
				echo Failed to start ${CONTAINER_NAME}
				docker stop ${CONTAINER_NAME} &> /dev/null
				exit 1
			else
				echo Started ${CONTAINER_NAME}
				exit 0
			fi
			;;
	esac
elif [[ $COMMAND == "stop" ]]; then
	$DIR/stop-container.sh ${CONTAINER_NAME}
fi