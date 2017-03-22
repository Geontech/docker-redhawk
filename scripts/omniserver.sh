#!/bin/bash
#
# Script expects arguments:
#  1) 'start' or 'stop'
#  2) 'bridge' or 'host' (bridge is default)
#
CONTAINER_NAME=omniserver
IMAGE_NAME=redhawk/${CONTAINER_NAME}

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

function print_status {
	$DIR/container-running.sh ${CONTAINER_NAME}
	case $? in
	2)
		echo omniserver does not exist.
		;;
	1)
		echo omniserver is not running.
		;;
	*)
		IP=$($DIR/omniserver-ip.sh)
		echo omniserver IP address: ${IP}
		;;
	esac
}

# Parameter checks
if [ -z ${1+x} ]; then
	print_status
	exit 0;
else
	if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
		echo Help: $0 start\|stop \[bridge\|host\]
		echo - \[\] arguments are optional
		echo - \"bridge\" is the default networking type
		exit 0
	fi
fi
COMMAND=$1
NETWORK=${2:-bridge}


# Check if the image is installed yet, if not, build it.
$DIR/image-exists.sh ${IMAGE_NAME}
if [ $? -gt 0 ]; then
	echo ${IMAGE_NAME} was not built yet, building now
	make -C $DIR/.. ${IMAGE_NAME} || { \
		echo Failed to build ${IMAGE_NAME}; exit 1;
	}
fi

# Check the container and the command
if [[ $COMMAND == "start" ]]; then
	$DIR/container-running.sh ${CONTAINER_NAME}
	if [ $? -eq 0 ]; then
		echo A ${CONTAINER_NAME} is already running.
		exit 0
	else
		echo Starting ${CONTAINER_NAME} ...
		if [[ $NETWORK == "bridge" ]]; then
			echo Bridge network selected
			docker run --rm -d \
				-p 2809:2809 \
				-p 11169:11169 \
				--name ${CONTAINER_NAME} ${IMAGE_NAME} &> /dev/null
		elif [[ $NETWORK == "host" ]]; then
			echo Host network selected
			docker run --rm -d \
				--network host \
				--name ${CONTAINER_NAME} ${IMAGE_NAME} &> /dev/null
		else
			echo Unknown network selected: ${NETWORK}
			exit 1
		fi
		
		# Verify it's running
		sleep 5
		$DIR/container-running.sh ${CONTAINER_NAME}
		if [ $? -gt 0 ]; then
			echo Failed to start ${IMAGE_NAME}
			docker stop ${CONTAINER_NAME} &> /dev/null
			exit 1
		else
			echo Started ${CONTAINER_NAME}
			print_status
			exit 0
		fi
	fi
elif [[ $COMMAND == "stop" ]]; then
	$DIR/container-running.sh ${CONTAINER_NAME}
	if [ $? -eq 0 ]; then
		# Is running...
		echo Stopping ${CONTAINER_NAME}...
		docker stop --time 5 ${CONTAINER_NAME} &> /dev/null

		# Verify it stopped
		sleep 6
		$DIR/container-running.sh ${CONTAINER_NAME}
		if [ $? -eq 0 ]; then
			echo Failed to stop ${CONTAINER_NAME}
			exit 1
		else
			echo Stopped ${CONTAINER_NAME}
			exit 0
		fi
	else
		echo ${CONTAINER_NAME} is already stopped
		exit 0
	fi
else
	echo Unknown command $COMMAND
	exit 1
fi
