#!/bin/bash
# Resolves what IP address is attached to the omni server container

# Detect the script's location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

OMNISERVER_NAME=omniserver

GUESS=""
$DIR/container-running.sh ${OMNISERVER_NAME}
if [ $? -eq 0 ]; then
	GUESS="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${OMNISERVER_NAME})"
	if [[ $GUESS == "" ]]; then
		GUESS="$(hostname -I | grep -oP '^(\d{1,3}\.?){4}')"
	fi
fi
echo $GUESS