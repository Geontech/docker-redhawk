#!/bin/bash
if [ -d /opt/rest-python/protobuf ]; then
	yum install -y protobuf-devel protobuf-python
	cd /opt/rest-python/protobuf
	protoc * --python_out=../rest/util_pb2
fi
