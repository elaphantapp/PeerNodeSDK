#!/bin/bash

set -o nounset
set -o errexit

CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
LIB_DIR="$(dirname $CURRENT_DIR)/lib";

export LD_LIBRARY_PATH="$LIB_DIR";
"$CURRENT_DIR"/PeerNodeLauncher $@;

