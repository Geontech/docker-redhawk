#!/bin/bash
# Returns :
#   2 if the container doesn't exist
#   1 if the container is stopped
#   0 if the container is running
RESULT="$(docker inspect -f {{.State.Running}} $1 2> /dev/null)"
if [ $? -eq 1 ]; then
	# Error, not found
	exit 2
else
	if [[ $RESULT == "true" ]]; then
		# Ok, running
		exit 0
	else
		# Error, stopped
		exit 1
	fi
fi