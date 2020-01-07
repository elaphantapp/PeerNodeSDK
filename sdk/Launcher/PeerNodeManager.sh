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
export PATH="$CURRENT_DIR:$PATH";
PeerNodeLauncher \
    -name "$PLUGIN_DIR/libMicroServiceManager.$PLUGIN_EXT" \
    -key  "ada94cfd614014da0fa855630fea2bf85eb1c9aaf687cc8210ff76751bcf4d1a" \
    -path "/tmp/PeerNode/" \
    -infopath "/tmp/PeerNode/info.txt";

