#!/bin/bash
#
# Start|Stop a REDHAWK Domain of the given name:
#    domain.sh start REDHAWK_2 SDRROOT_VOLUME OMNISERVER
#              stop  REDHAWK_2
#
# Notes: 
#   The third and fourth arguments are optional on start.  
#   If SDRROOT_VOLUME is not desired, but OMNISERVER is, set it to DEFAULT.
#   If OMNISERVER is not provided, the omniserver container MUST be running.

if [ -z ${1+x} ]; then
	echo You must provide a command, start or stop
	exit 1
else
	if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
		echo Help: 
		echo STARTING: $0 start DOMAIN_NAME \[SDRROOT_VOLUME\] \[OMNISERVER\]
		echo STOPPING: $0 stop  DOMAIN_NAME
		echo - \[\] arguments are optional
		echo - DOMAIN_NAME is the name to assign to the Domain \(and container\)
		echo - SDRROOT_VOLUME is a named Docker volume to use for SDROOT
		echo - OMNISERVER is the IP address of a \*remote\* Omni server
		exit 0
	fi
fi
if [ -z ${2+x} ]; then
	echo You must provide a domain \(container\) name
	exit 1
fi
COMMAND=$1
CONTAINER_NAME=$2
SDRROOT_VOLUME=${3:-DEFAULT}
OMNISERVER=${4:-DEFAULT}
OMNISERVER_NAME=omniserver
IMAGE_NAME=redhawk/domain

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Get volume command
SDRROOT_CMD="$($DIR/sdrroot-cmd.sh $SDRROOT_VOLUME)"

# Check if the image is installed yet, if not, build it.
$DIR/image-exists.sh ${IMAGE_NAME}
if [ $? -gt 0 ]; then
	echo "${IMAGE_NAME} was not built yet, building now"
	make -C $DIR/..  ${IMAGE_NAME} || { \
		echo Failed to build ${IMAGE_NAME}; exit 1;
	}
fi

# Check if a domain is already running in that name.
if [[ $COMMAND == "start" ]]; then
	$DIR/container-running.sh ${CONTAINER_NAME}
	if [ $? -eq 0 ]; then
		echo Domain ${CONTAINER_NAME} is already running
		exit 0
	else
		if [[ ${OMNISERVER} == "DEFAULT" ]]; then
			# IP not provided, check for omniserver
			$DIR/container-running.sh ${OMNISERVER_NAME}
			if [ $? -gt 0 ]; then
				echo No IP was provided for the Omni Server
				echo The omniserver Docker Container is not running
				echo Please start omniserver or provide a service IP.
				exit 1
			fi
			# Get the omniserver IP and run linked to the server.
			OMNISERVER="$($DIR/omniserver-ip.sh)"
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
	fi
elif [[ $COMMAND == "stop" ]]; then
	$DIR/container-running.sh ${CONTAINER_NAME}
	case $? in
	2)
		echo ${CONTAINER_NAME} does not exist
		exit 1
		;;
	1)
		echo ${CONTAINER_NAME} is already stopped
		exit 0
		;;
	*)
		echo Stopping ${CONTAINER_NAME} ...
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
		;;
	esac
else
	echo Unknown command ${COMMAND}
	exit 1
fi