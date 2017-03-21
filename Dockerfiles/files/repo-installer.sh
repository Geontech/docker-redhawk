#!/bin/bash
set -e

echo RH_VERSION: "${RH_VERSION:?Need to set RH_VERSION}"

wget https://github.com/RedhawkSDR/redhawk/releases/download/${RH_VERSION}/redhawk-yum-${RH_VERSION}-el7-x86_64.tar.gz
tar xzf redhawk-yum-${RH_VERSION}-el7-x86_64.tar.gz
mv redhawk-${RH_VERSION}-el7-x86_64 redhawk-yum
pushd redhawk-yum

cat<<EOF|sed 's@LDIR@'`pwd`'@g'|tee /etc/yum.repos.d/redhawk.repo
[redhawk]
name=REDHAWK Repository
baseurl=file://LDIR/
enabled=1
gpgcheck=0
EOF

