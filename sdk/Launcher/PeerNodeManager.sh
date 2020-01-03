#!/bin/bash

set -o nounset
set -o errexit

CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
LIB_DIR="$(dirname $CURRENT_DIR)/lib";
PLUGIN_DIR="$LIB_DIR/PeerNodePlugins";
PLUGIN_EXT="so";
if [ "$(uname -s)" == "Darwin" ]; then
    PLUGIN_EXT="dylib";
fi

export LD_LIBRARY_PATH="$LIB_DIR";
"$CURRENT_DIR"/PeerNodeLauncher \
    -name "$PLUGIN_DIR/libMicroServiceManager.$PLUGIN_EXT" \
    -key "02bc11aa5c35acda6f6f219b94742dd9a93c1d11c579f98f7e3da05ad910a48306" \
    -path "/tmp/PeerNode/" \
    -info "/tmp/PeerNode/info.txt";

