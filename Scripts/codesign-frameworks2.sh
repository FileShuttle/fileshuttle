#!/bin/sh

#  codesign-frameworks2.sh
#  Fileshuttle
#
#  Created by Anthony Somerset on 12/10/2015.
#
LOCATION="${BUILT_PRODUCTS_DIR}"/"${FRAMEWORKS_FOLDER_PATH}"
IDENTITY="Mac Developer: Anthony Somerset (A4ZG8D27HY)"
codesign --verbose --force --sign "$IDENTITY" "$LOCATION/CURLHandle.framework/Versions/A"
codesign --verbose --force --sign "$IDENTITY" "$LOCATION/Growl.framework/Versions/A"
codesign --verbose --force --sign "$IDENTITY" "$LOCATION/ShortcutRecorder.framework/Versions/A"
codesign --verbose --force --sign "$IDENTITY" "$LOCATION/RegexKit.framework/Versions/A"