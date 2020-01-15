#!/bin/bash

set -o nounset
set -o errexit

CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$CURRENT_DIR";

source "download-urls";
if [ ! -f ".$CONTACT_ZIPNAME" ]; then
    echo "Downloading $CONTACT_ZIPNAME...";
    #echo curl --location "$CONTACT_URL" --output "$CONTACT_ZIPNAME";
    curl --location "$CONTACT_URL" --output "$CONTACT_ZIPNAME";
    unzip -t "$CONTACT_ZIPNAME";
    touch ".$CONTACT_ZIPNAME";
else
    echo "$CONTACT_ZIPNAME exists.";
fi

CONTACT_FRAMEWORKS=("CrossPL.framework" "ContactSDK.framework");
for framework in ${CONTACT_FRAMEWORKS[@]}; do
    if [ ! -f "$framework/.unpacked" ]; then
        echo "Unpacking $framework...";
        rm -rf "$framework";
        unzip $CONTACT_ZIPNAME "$framework/*";
        touch "$framework/.unpacked";
    else
        echo "$framework exists.";
    fi
done

echo "Ensure depend frameworks done!"
