#!/bin/sh
# Archives the iOS app (with the Apple Watch app inside) for the App Store.
#   scripts/archive-ios.sh           -> ios/build/Langria.xcarchive and ios/build/export/Langria.ipa
#   scripts/archive-ios.sh --upload  -> also uploads the build to App Store Connect
# The build number is the commit count, so each commit on master gets a new,
# larger one (App Store Connect refuses a number it has already seen).
# Signing uses the Team in ios/Local.xcconfig and the Apple account signed in to Xcode.
set -eu
root=$(git rev-parse --show-toplevel)
cd "$root"

upload=false
[ "${1:-}" = --upload ] && upload=true

if [ -n "$(git status --porcelain -- ios extension/lib)" ]; then
  echo "warning: ios/ or extension/lib/ has uncommitted changes; they go into the build" >&2
fi
grep -q '^DEVELOPMENT_TEAM *= *[A-Z0-9]\{10\}' ios/Local.xcconfig 2>/dev/null || {
  echo "error: set DEVELOPMENT_TEAM in ios/Local.xcconfig (see Local.xcconfig.example)" >&2; exit 1; }

# The settings screen shows this commit next to the version.
.githooks/write-version
build=$(git rev-list --count HEAD)
version=$(sed -n 's/^ *MARKETING_VERSION: *"\([^"]*\)".*/\1/p' ios/project.yml)

cd ios
xcodegen generate --quiet
rm -rf build/Langria.xcarchive build/export
xcodebuild archive -quiet \
  -project Langria.xcodeproj -scheme Langria -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Langria.xcarchive \
  -allowProvisioningUpdates CURRENT_PROJECT_VERSION="$build"

options=$(mktemp -d)/ExportOptions.plist
trap 'rm -rf "$(dirname "$options")"' EXIT
destination=export
$upload && destination=upload
cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$destination</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF
xcodebuild -exportArchive -quiet -archivePath build/Langria.xcarchive \
  -exportPath build/export -exportOptionsPlist "$options" -allowProvisioningUpdates

if $upload; then
  echo "uploaded $version ($build) to App Store Connect"
else
  echo "$root/ios/build/export ($version ($build)); run with --upload to send it to App Store Connect"
fi
