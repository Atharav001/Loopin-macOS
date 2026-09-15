#!/usr/bin/env bash
set -e

echo "=== Building Logtrackin Native macOS App ==="
swift build -c release

APP_NAME="Logtrackin"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Creating App Bundle: ${BUNDLE_DIR}..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

if [ -f "assets/AppIcon.icns" ]; then
    cp "assets/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

BIN_PATH=$(swift build -c release --show-bin-path)
cp "${BIN_PATH}/Loopin" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Logtrackin</string>
    <key>CFBundleIdentifier</key>
    <string>com.atharav.logtrackin</string>
    <key>CFBundleName</key>
    <string>Logtrackin</string>
    <key>CFBundleDisplayName</key>
    <string>Logtrackin</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Logtrackin uses on-device speech recognition to let you log your activities by voice.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Logtrackin uses your microphone for voice activity logging.</string>
</dict>
</plist>
EOF

echo "✓ Successfully built ${BUNDLE_DIR}!"
echo "Run with: open Logtrackin.app"
