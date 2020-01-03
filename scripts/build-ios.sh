#!/bin/bash - 

set -o errexit
set -o nounset

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
PROJECT_DIR=$(dirname "${SCRIPT_DIR}");
BUILD_DIR="$PROJECT_DIR/build";
PACKAGE_DIR="$BUILD_DIR/package";

PROJECT_NAME="PeerNodeSDK";
PROJECT_BUILDTYPE="Release";
PROJECT_REVISION="$(git rev-list --count HEAD)";
PROJECT_VERSION="v0.1.$PROJECT_REVISION";

"$SCRIPT_DIR/build.sh" --platform iOS --arch x86_64;
"$SCRIPT_DIR/build.sh" --platform iOS --arch arm64;

IOS_DIR="$PROJECT_DIR/ios";
cd "$IOS_DIR";
export CURRENT_PROJECT_VERSION=${PROJECT_REVISION};
export CURRENT_PROJECT_VERSIONNAME=${PROJECT_VERSION/v/};
echo "Building sdk ...";
xcodebuild -target "sdk" -configuration "${PROJECT_BUILDTYPE}" -arch arm64  -sdk "iphoneos" \
    CURRENT_PROJECT_VERSION=${PROJECT_REVISION} CURRENT_PROJECT_VERSIONNAME=${PROJECT_VERSION/v/};
xcodebuild -target "sdk" -configuration "${PROJECT_BUILDTYPE}" -arch x86_64 -sdk "iphonesimulator" \
    CURRENT_PROJECT_VERSION=${PROJECT_REVISION} CURRENT_PROJECT_VERSIONNAME=${PROJECT_VERSION/v/};

echo "Lipo sdk ...";
TARGET_SDK="$PACKAGE_DIR/PeerNodeSDK.framework";
rm -rf "$TARGET_SDK" && mkdir -p "$TARGET_SDK";
cp -r "$IOS_DIR/build/${PROJECT_BUILDTYPE}-iphonesimulator/PeerNodeSDK.framework/"* "$TARGET_SDK/";
cp -r "$IOS_DIR/build/${PROJECT_BUILDTYPE}-iphoneos/PeerNodeSDK.framework/"* "$TARGET_SDK/";
rm "$TARGET_SDK/PeerNodeSDK";
rm -rf "$TARGET_SDK/_CodeSignature";
lipo -create -output "$TARGET_SDK/PeerNodeSDK" \
	"$IOS_DIR/build/${PROJECT_BUILDTYPE}-iphoneos/PeerNodeSDK.framework/PeerNodeSDK" \
	"$IOS_DIR/build/${PROJECT_BUILDTYPE}-iphonesimulator/PeerNodeSDK.framework/PeerNodeSDK";

git tag --force ${PROJECT_VERSION}

TARBALL_PATH="$PACKAGE_DIR/${PROJECT_NAME}-ios-${PROJECT_VERSION}.zip";
cd $PACKAGE_DIR;
rm -rf "$TARBALL_PATH";
zip -r "$TARBALL_PATH" $(basename "$TARGET_SDK");

echo "Done!!!";

