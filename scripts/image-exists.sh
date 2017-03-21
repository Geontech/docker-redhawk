#!/bin/bash
# Returns :
#   1 if it failed to find the image
#   0 if the image exists 
if [[ "$(docker images -q $1)" = "" ]]; then
	exit 1
else
	exit 0
fi