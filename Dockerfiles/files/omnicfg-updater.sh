#!/bin/bash
set -e

# If OMNISERVICEIP hasn't been set, use our IP so the service is exposed
if [ "${OMNISERVICEIP}" == "127.0.0.1" ]; then
	export OMNISERVICEIP=`hostname -I | grep -oP "^(\d{1,3}\.?){4}"`
fi

echo Setting OmniORB Service IP to: $OMNISERVICEIP
sed -i "s/127\.0\.0\.1/$OMNISERVICEIP/g" /etc/omniORB.cfg
