#!/bin/bash
# FlowDesk DMG Creation Script
# Requires: FlowDesk.app in build/mac/

APP_NAME="FlowDesk"
VERSION="1.1.7"
BUILD_DIR="build/mac"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
VOL_NAME="${APP_NAME} Installer"

echo "💿 Creating DMG for ${APP_NAME} v${VERSION}..."

# Clean up
rm -f "${BUILD_DIR}/${DMG_NAME}"
rm -rf "/tmp/flowdesk_dmg"

# Create staging area
mkdir -p "/tmp/flowdesk_dmg"
cp -R "${BUILD_DIR}/${APP_NAME}.app" "/tmp/flowdesk_dmg/"

# Add Applications shortcut link
ln -s /Applications "/tmp/flowdesk_dmg/Applications"

# Create initial DMG
hdiutil create -volname "${VOL_NAME}" -srcfolder "/tmp/flowdesk_dmg" -ov -format UDZO "${BUILD_DIR}/${DMG_NAME}"

echo "✅ DMG Created: ${BUILD_DIR}/${DMG_NAME}"

# Clean up
rm -rf "/tmp/flowdesk_dmg"
