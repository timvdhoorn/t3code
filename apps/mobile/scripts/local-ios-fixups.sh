#!/usr/bin/env bash
# Post-prebuild fixups for local device builds signed with a fork's own Apple team.
# Run from apps/mobile after `expo prebuild --platform ios`, before xcodebuild.
#
#   T3CODE_IOS_TEAM_ID=XXXXXXXXXX ./scripts/local-ios-fixups.sh
set -euo pipefail

TEAM_ID="${T3CODE_IOS_TEAM_ID:?T3CODE_IOS_TEAM_ID must be set}"
IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../ios" && pwd)"
APP_PROJECT="$IOS_DIR/T3Code.xcodeproj/project.pbxproj"
PODS_PROJECT="$IOS_DIR/Pods/Pods.xcodeproj/project.pbxproj"

# Expo only writes DEVELOPMENT_TEAM into the app and widget targets, so the share
# extension fails with "requires a development team".
if ! grep -q "DEVELOPMENT_TEAM = $TEAM_ID;" <(grep -A1 "expo-sharing-extension" "$APP_PROJECT" || true); then
  perl -0pi -e "s/(PRODUCT_BUNDLE_IDENTIFIER = [^;]*\.sharing;)/DEVELOPMENT_TEAM = $TEAM_ID;\n\t\t\t\t\$1/g" "$APP_PROJECT"
fi

# Xcode 27 rejects deployment targets below 15.0; some pod resource bundles still
# inherit 12.x from their podspec.
perl -pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = 1[0-4](\.\d+)?;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' "$PODS_PROJECT"

echo "fixups applied: team $TEAM_ID on share extension, pod deployment targets raised to 15.0"
