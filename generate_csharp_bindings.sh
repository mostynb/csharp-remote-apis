#!/bin/bash
set -euxo pipefail

rm -rf dst
mkdir dst

PROTOC_VER=25.2
PROTOC_URL=https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VER}/protoc-${PROTOC_VER}-linux-x86_64.zip
PROTOC_ZIP=$(basename $PROTOC_URL)
PROTOC_DIR=$(basename $PROTOC_URL .zip)
PROTOC_BIN=${PROTOC_DIR}/bin/protoc

if [ ! -e "$PROTOC_BIN" ]
then
	if [ ! -e "$PROTOC_ZIP" ]
	then
		wget "$PROTOC_URL"
	fi

	if [ ! -e "$PROTOC_BIN" ]
	then
		rm -rf "$PROTOC_DIR"
		mkdir "$PROTOC_DIR"
		unzip "$PROTOC_ZIP" -d "$PROTOC_DIR"
	fi
fi

# Generate bindings for all of these:
find remote-apis/build -type f -name '*.proto' -exec "$PROTOC_BIN" -I=. --csharp_out=dst '{}' ';'

# Generate bindings for the protos transitively included by remote-apis:
for pb in protobuf/src/google/protobuf/any.proto \
		protobuf/src/google/protobuf/duration.proto \
		protobuf/src/google/protobuf/timestamp.proto \
		protobuf/src/google/protobuf/wrappers.proto \
		googleapis/google/api/annotations.proto \
		googleapis/google/api/launch_stage.proto \
		googleapis/google/api/client.proto \
		googleapis/google/api/http.proto \
		googleapis/google/rpc/status.proto \
		googleapis/google/bytestream/bytestream.proto \
		googleapis/google/longrunning/operations.proto
do
	"$PROTOC_BIN" -I=googleapis -I=protobuf/src --csharp_out=dst "$pb"
done

echo "Take a look at the generated bindings in dst/"
ls dst/
