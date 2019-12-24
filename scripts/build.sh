#!/bin/bash

set -o errexit
set -o nounset

CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
PROJECT_DIR=$(dirname "$CURRENT_DIR")
DEPENDS_DIR="$PROJECT_DIR/config";

cd "$PROJECT_DIR";
git submodule init;
git submodule update;

build_extfunc_depends()
{
	#"$DEPENDS_DIR/scripts/build-curl.sh" $@;
    #if [[ $CFG_TARGET_PLATFORM == "iOS" ]]; then
        #loginfo "Ignore to build sqlite for iOS, use buildin."
    #else
        #"$DEPENDS_DIR/scripts/build-sqlite.sh" $@;
    #fi

    local params=${@//--force-build/}

    echo ===============
    echo $CFG_TARGET_PLATFORM
    echo ===============

    "$DEPENDS_DIR/scripts/build-Elastos.NET.Carrier.Native.SDK.sh" $params;

    "$DEPENDS_DIR/scripts/build-json.sh" $params;

    "$DEPENDS_DIR/scripts/build-openssl.sh" $params;

    "$DEPENDS_DIR/scripts/build-curl.sh" $params

    "$DEPENDS_DIR/scripts/build-sqlite.sh" $params

    "$DEPENDS_DIR/scripts/build-Elastos.SDK.Keypair.C.sh" $params;

    #CFG_BUILD_ROOT
    "$DEPENDS_DIR/scripts/build-Elastos.SDK.ElephantWallet.Contact.sh" $params;
}

export CFG_PROJECT_NAME="PeerNodeSDK";
export CFG_PROJECT_DIR="$PROJECT_DIR";
export CFG_CMAKELIST_DIR="$PROJECT_DIR/sdk";
source "$DEPENDS_DIR/scripts/build.sh" $@ --force-build;

