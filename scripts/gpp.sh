#!/bin/bash
#

IMAGE_NAME=redhawk/gpp

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

function print_status() {
	docker ps -a \
		--filter="ancestor=${IMAGE_NAME}"\
		--format="table {{.Names}}\t{{.Status}}"
}

function usage () {
	cat <<EOF

Usage: $0 start|stop
	[-g|--gpp    GPP_NAME]    GPP Device name, default is GPP_[UUID]
	[-n|--node   NODE_NAME]   Node Name, Defaults to DevMgr_GPP_NAME
	[-d|--domain DOMAIN_NAME] Domain Name, default is REDHAWK_DEV
	[-o|--omni   OMNISERVER]  IP to the OmniServer (detected: ${OMNISERVER})
	[-p|--print]              Just print resolved settings

Examples:
	Start or stop a node:
		$0 start|stop --node MyGPP --domain REDHAWK_TEST2

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
			COMMAND="$1"
			;;
		-g|--gpp)
			GPP_NAME="$2"
			shift
			;;
		-n|--node)
			NODE_NAME="$2"
			shift
			;;
		-d|--domain)
			DOMAIN_NAME="$2"
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

# Enforce defaults
GPP_NAME=${GPP_NAME:-GPP_$(uuidgen)}
NODE_NAME=${NODE_NAME:-DevMgr_${GPP_NAME}}
DOMAIN_NAME=${DOMAIN_NAME:-REDHAWK_DEV}

if ! [ -z ${JUST_PRINT+x} ]; then
	cat <<EOF
Resolved Settings:
	COMMAND:      ${COMMAND}
	GPP_NAME:     ${GPP_NAME}
	NODE_NAME:    ${NODE_NAME}
	DOMAIN_NAME:  ${DOMAIN_NAME}
	OMNISERVER:   ${OMNISERVER}
EOF
	exit 0
fi

# Check if the image is installed yet, if not, build it.
$DIR/image-exists.sh ${IMAGE_NAME}
if [ $? -gt 0 ]; then
	echo "${IMAGE_NAME} was not built yet, building now"
	make -C $DIR/..  ${IMAGE_NAME} || { \
		echo Failed to build ${IMAGE_NAME}; exit 1;
	}
fi

# The container name will be the node name
CONTAINER_NAME=${NODE_NAME}

# Handle the command
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
				# Get the omniserver IP and run linked to the server.
				echo Connecting to local omniserver: $OMNISERVER
				docker run --rm -it \
				    -e GPPNAME=${GPP_NAME} \
				    -e NODENAME=${NODE_NAME} \
				    -e DOMAINNAME=${DOMAIN_NAME} \
				    -e OMNISERVICEIP=${OMNISERVER} \
					--link ${OMNISERVER_NAME} \
					--name ${CONTAINER_NAME} \
					${IMAGE_NAME} /bin/bash -l # &> /dev/null
			else
				# IP is provided, start domain with service IP
				echo Connecting to remote omniserver: $OMNISERVER
				docker run --rm -d \
				    -e GPPNAME=${GPP_NAME} \
				    -e NODENAME=${NODE_NAME} \
				    -e DOMAINNAME=${DOMAIN_NAME} \
				    -e OMNISERVICEIP=${OMNISERVER} \
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
fi