#!/bin/zsh
# Builds "Home Assistant iOS Simulator Installer.app" into ./build.
#
# Environment:
#   GITHUB_CLIENT_ID  Client ID of the GitHub OAuth App (device flow enabled). Required for "Sign In".
#   SIGN_IDENTITY     Code signing identity. Defaults to ad-hoc ("-"), which only runs on this Mac.
#   NOTARY_PROFILE    notarytool keychain profile. When set, the app is notarized and stapled.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Home Assistant iOS Simulator Installer"
EXECUTABLE="HASimulatorInstaller"
BUNDLE_ID="io.home-assistant.SimulatorInstaller"
VERSION="${VERSION:-1.0}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"

APP="build/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

xcrun actool "$PWD/Resources/AppIcon.icon" \
    --compile "$PWD/$APP/Contents/Resources" \
    --app-icon AppIcon \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --output-partial-info-plist "$PWD/build/AppIcon-partial.plist" \
    > /dev/null
rm "$PWD/build/AppIcon-partial.plist"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>GitHubClientID</key>
    <string>${GITHUB_CLIENT_ID:-}</string>
</dict>
</plist>
PLIST

codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    ZIP="build/$EXECUTABLE.zip"
    ditto -c -k --keepParent "$APP" "$ZIP"
    xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    rm "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
fi

if [[ -z "${GITHUB_CLIENT_ID:-}" ]]; then
    echo "warning: GITHUB_CLIENT_ID is not set; Sign In is disabled (a signed-in gh CLI still works)."
fi

echo "Built $APP"
