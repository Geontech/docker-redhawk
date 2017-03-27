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

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Volume labels
source $DIR/volume-labels.sh

# Usage instructions
function usage () {
	cat <<EOF

Usage: $0 ...
	[sdrroot|workspace]
	create  sdrroot|workspace  VOLUME_NAME
	delete  VOLUME_NAME

Examples:
	List all volumes:
		$0

	List only sdrroot volumes:
		$0 sdrroot

	Create a workspace volume:
		$0 create workspace MyWorkspace

EOF
}

function print_status_sdrroot () {
	cat <<EOF

SDRROOT Volumes:
VOLUME NAME
$(docker volume ls --format="{{.Name}}" --filter="label=${SDRROOT_LABEL}")

Volumes mounted to domain or development:
$(docker ps -a --filter="ancestor=redhawk/domain" --format="table {{.Names}}\t{{.Mounts}}")
$(docker ps -a --filter="ancestor=redhawk/development" --format="{{.Names}}\t{{.Mounts}}")

EOF
}

function print_status_workspace () {
	cat <<EOF

Workspace Volumes:
VOLUME NAME
$(docker volume ls --format="{{.Name}}" --filter="label=${WORKSPACE_LABEL}")

Volumes mounted to development workspaces (IDEs):
$(docker ps -a --filter="ancestor=redhawk/development" --format="table {{.Names}}\t{{.Mounts}}")

EOF
}

function print_status () {
	print_status_sdrroot
	print_status_workspace
}

if [ -z ${1+x} ]; then
	print_status
	exit 0
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		create|delete)
			if ! [ -z ${COMMAND+x} ]; then
				usage
				echo ERROR: The create and delete commands are mutually exclusive.
				exit 1
			fi
			COMMAND="$1"
			;;
		sdrroot|workspace)
			if ! [ -z ${VOLUME_TYPE} ]; then
				usage
				echo ERROR: Only specify one volume type: sdrroot or workspace
				exit 1
			fi
			
			VOLUME_TYPE="redhawk/$1"
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			VOLUME_NAME="$1"
			;;
	esac
	shift # past argument
done

function must_specify () {
	if [ -z ${2+x} ]; then
		usage
		echo ERROR: You must specify a $1
		exit 1
	fi
}

# Do the work
case $COMMAND in
	create)
		must_specify 'volume type: sdrroot or workspace' ${VOLUME_TYPE}
		must_specify 'unique volume name' ${VOLUME_NAME}

		$DIR/volume-exists.sh ${VOLUME_NAME} ${VOLUME_TYPE}
		if [ $? -eq 0 ]; then
			echo The volume ${VOLUME_NAME} already exists
			exit 2
		else
			echo Creating... $(docker volume create --label ${VOLUME_TYPE} ${VOLUME_NAME})	
		fi
		;;

	delete)
		must_specify 'unique volume name' ${VOLUME_NAME}

		$DIR/volume-exists.sh ${VOLUME_NAME} ${VOLUME_TYPE}
		if [ $? -eq 1 ]; then
			echo The volume ${VOLUME_NAME} does not exist
		else
			echo Removing... $(docker volume rm ${VOLUME_NAME})
		fi
		;;
	*)
		case ${VOLUME_TYPE} in
			${SDRROOT_LABEL})
				print_status_sdrroot
				;;
			${WORKSPACE_LABEL})
				print_status_workspace
				;;
			*)
				print_status
				;;
		esac
		;;
esac
