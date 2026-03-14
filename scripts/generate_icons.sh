#!/bin/bash
# FlowDesk Icon Generator
# Usage: ./scripts/generate_icons.sh <path-to-source-1024x1024.png>
# Requires: sips (built-in macOS), iconutil (built-in macOS), ImageMagick (brew install imagemagick)

set -e

SOURCE="${1:-assets/logo.png}"

if [ ! -f "$SOURCE" ]; then
  echo "Error: Source image not found at $SOURCE"
  echo "Usage: ./scripts/generate_icons.sh <path-to-source-1024x1024.png>"
  exit 1
fi

echo "Generating FlowDesk icons from: $SOURCE"

mkdir -p assets/icons
mkdir -p mac-client/KBFlow/Assets.xcassets/AppIcon.appiconset

# ── macOS .icns ──────────────────────────────────────────────────────────────
ICONSET="assets/icons/AppIcon.iconset"
mkdir -p "$ICONSET"

sizes=(16 32 64 128 256 512 1024)
for size in "${sizes[@]}"; do
  sips -z $size $size "$SOURCE" --out "${ICONSET}/icon_${size}x${size}.png" > /dev/null
  if [ $size -le 512 ]; then
    double=$((size * 2))
    sips -z $double $double "$SOURCE" --out "${ICONSET}/icon_${size}x${size}@2x.png" > /dev/null
  fi
done

iconutil -c icns "$ICONSET" -o "assets/icons/AppIcon.icns"
cp "assets/icons/AppIcon.icns" "mac-client/KBFlow/Assets.xcassets/AppIcon.appiconset/"
echo "✓ macOS AppIcon.icns"

# Generate the Contents.json for Xcode
cat > mac-client/KBFlow/Assets.xcassets/AppIcon.appiconset/Contents.json << 'JSONEOF'
{
  "images": [
    { "size": "16x16",   "idiom": "mac", "filename": "icon_16x16.png",    "scale": "1x" },
    { "size": "16x16",   "idiom": "mac", "filename": "icon_16x16@2x.png", "scale": "2x" },
    { "size": "32x32",   "idiom": "mac", "filename": "icon_32x32.png",    "scale": "1x" },
    { "size": "32x32",   "idiom": "mac", "filename": "icon_32x32@2x.png", "scale": "2x" },
    { "size": "128x128", "idiom": "mac", "filename": "icon_128x128.png",  "scale": "1x" },
    { "size": "128x128", "idiom": "mac", "filename": "icon_128x128@2x.png","scale": "2x" },
    { "size": "256x256", "idiom": "mac", "filename": "icon_256x256.png",  "scale": "1x" },
    { "size": "256x256", "idiom": "mac", "filename": "icon_256x256@2x.png","scale": "2x" },
    { "size": "512x512", "idiom": "mac", "filename": "icon_512x512.png",  "scale": "1x" },
    { "size": "512x512", "idiom": "mac", "filename": "icon_512x512@2x.png","scale": "2x" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
JSONEOF

# Copy individual PNGs to the xcassets folder
for f in "$ICONSET"/*.png; do
  cp "$f" "mac-client/KBFlow/Assets.xcassets/AppIcon.appiconset/"
done
echo "✓ Xcode AppIcon.appiconset"

# ── Windows .ico ─────────────────────────────────────────────────────────────
if command -v convert &>/dev/null; then
  convert "$SOURCE" \
    \( -clone 0 -resize 256x256 \) \
    \( -clone 0 -resize 128x128 \) \
    \( -clone 0 -resize 64x64 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 16x16 \) \
    -delete 0 \
    "assets/icons/icon.ico"
  cp "assets/icons/icon.ico" "windows-server/src/icon.ico"
  echo "✓ Windows icon.ico"
else
  echo "⚠ ImageMagick not found — skipping .ico generation"
  echo "  Install with: brew install imagemagick"
fi

# ── Flat PNGs for reference ───────────────────────────────────────────────────
for size in 16 32 64 128 256 512 1024; do
  sips -z $size $size "$SOURCE" --out "assets/icons/logo_${size}.png" > /dev/null
done
echo "✓ Flat PNG exports"

echo ""
echo "Done! Icon assets generated in assets/icons/"
echo "  macOS:   assets/icons/AppIcon.icns"
echo "  Windows: assets/icons/icon.ico (requires ImageMagick)"
echo "  PNGs:    assets/icons/logo_*.png"
