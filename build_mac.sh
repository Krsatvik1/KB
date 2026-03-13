#!/bin/bash
set -e

echo "Building KBFlow Mac App..."

APP_NAME="KBFlow.app"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"

# Compile all Swift files using swiftc
swiftc -o "${MACOS_DIR}/KBFlow" \
  mac-client/KBFlow/App/*.swift \
  mac-client/KBFlow/Input/*.swift \
  mac-client/KBFlow/Network/*.swift \
  mac-client/KBFlow/UI/*.swift

# Create Info.plist
cat << 'EOF' > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KBFlow</string>
    <key>CFBundleIdentifier</key>
    <string>com.kbflow.app</string>
    <key>CFBundleName</key>
    <string>KBFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>KBFlow needs access to intercept events.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>KBFlow needs accessibility access to intercept global keyboard and mouse events.</string>
</dict>
</plist>
EOF

echo "Build complete! App is located at ${APP_BUNDLE}"
echo "You can move it to /Applications and run it."
