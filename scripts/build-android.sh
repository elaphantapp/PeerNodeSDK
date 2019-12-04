#!/bin/bash - 

set -o errexit
set -o nounset

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
PROJECT_DIR=$(dirname "${SCRIPT_DIR}");
BUILD_DIR="$PROJECT_DIR/build";

PROJECT_NAME="PeerNodeSDK";
PROJECT_BUILDTYPE="Release";
PROJECT_REVISION="$(git rev-list --count HEAD)";
PROJECT_VERSION="v0.1.$PROJECT_REVISION";

TARGET_PATH="$BUILD_DIR/${PROJECT_NAME}-${PROJECT_VERSION}.aar";

ANDROID_DIR="$PROJECT_DIR/android";
cd "$ANDROID_DIR";
./gradlew :sdk:assembleDebug -P versionCode=${PROJECT_REVISION} -P versionName=${PROJECT_VERSION/v/}
rm -rf "$TARGET_PATH";
mkdir -p "$BUILD_DIR/";
cp "$ANDROID_DIR/sdk/build/outputs/aar/sdk-debug.aar" "$TARGET_PATH";
git tag --force ${PROJECT_VERSION}


TARBALL_PATH="$BUILD_DIR/${PROJECT_NAME}-android-${PROJECT_VERSION}.zip";
cd "$BUILD_DIR";
zip -r "$TARBALL_PATH" . -i $(basename "$TARGET_PATH");

echo "Done!!!";

