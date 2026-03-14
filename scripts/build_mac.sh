#!/bin/bash
# FlowDesk Mac Build Script
# Combines all Swift files into a standalone .app bundle using swiftc.

set -e

APP_NAME="FlowDesk"
BUILD_DIR="build/mac"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🚀 Building $APP_NAME..."

# 1. Clean and Create Bundle Structure
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 2. Compile Swift Files
# Note: In a larger project, xcodebuild is preferred, but for this standalone tool, swiftc is fast.
SWIFT_FILES=$(find mac-client/KBFlow -name "*.swift")

echo "📦 Compiling Swift sources..."
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macosx14.0 \
    $SWIFT_FILES \
    -o "$MACOS/$APP_NAME" \
    -parse-as-library

# 3. Copy Assets
if [ -f "assets/icons/AppIcon.icns" ]; then
    cp "assets/icons/AppIcon.icns" "$RESOURCES/"
fi

# 4. Create PkgInfo & Info.plist
echo "APPL????" > "$CONTENTS/PkgInfo"

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.flowdesk.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.3</string>
    <key>CFBundleVersion</key>
    <string>15</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Fix permissions (Crucial for ad-hoc builds)
chmod +x "$MACOS/$APP_NAME"

echo "✅ $APP_NAME.app built successfully in $BUILD_DIR"
