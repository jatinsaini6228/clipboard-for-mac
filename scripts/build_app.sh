#!/usr/bin/env bash
set -euo pipefail

# Directory of the project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="Clipboard.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📋 [1/4] Compiling Clipboard main app in release mode..."
cd "${PROJECT_DIR}"
swift build -c release --product Clipboard

BINARY_PATH="$(swift build -c release --show-bin-path)/Clipboard"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "📦 [2/4] Assembling macOS Application Bundle (${APP_NAME})..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BINARY_PATH}" "${MACOS_DIR}/Clipboard"
chmod +x "${MACOS_DIR}/Clipboard"

# Copy Icon and Logo Assets
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi
if [ -f "${PROJECT_DIR}/Resources/app_logo.png" ]; then
    cp "${PROJECT_DIR}/Resources/app_logo.png" "${RESOURCES_DIR}/app_logo.png"
fi

echo "📝 [3/4] Generating App Info.plist..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Clipboard</string>
    <key>CFBundleIdentifier</key>
    <string>com.clipboard.mac</string>
    <key>CFBundleName</key>
    <string>Clipboard</string>
    <key>CFBundleDisplayName</key>
    <string>Clipboard</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.clipboard.mac.url</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>clipboard</string>
            </array>
        </dict>
    </array>
    <key>NSAccessibilityUsageDescription</key>
    <string>Clipboard for Mac uses accessibility features to paste copied clips directly into your active application.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Clipboard uses Apple Events to paste clips directly into your active application.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "🔏 [4/4] Applying macOS code signature with persistent designated requirement..."
codesign -s - --force --deep -r '=designated => identifier "com.clipboard.mac"' "${APP_DIR}"

if [ -d "/Applications/Clipboard.app" ]; then
    echo "📲 Updating /Applications/Clipboard.app..."
    rm -rf "/Applications/Clipboard.app"
    cp -R "${APP_DIR}" "/Applications/Clipboard.app"
    codesign -s - --force --deep -r '=designated => identifier "com.clipboard.mac"' "/Applications/Clipboard.app"
fi

echo "✨ Build complete!"
echo "--------------------------------------------------------"
echo "Application bundle created at:"
echo "  ${APP_DIR}"
echo ""
echo "To run the app:"
echo "  open \"${APP_DIR}\""
echo ""
echo "Installed to /Applications/Clipboard.app"
echo "--------------------------------------------------------"
