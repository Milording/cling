#!/bin/bash
# Builds Cling in release mode and assembles dist/Cling.app.
# Usage: scripts/bundle.sh [--install]   (--install copies to /Applications)
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=dist/Cling.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Cling "$APP/Contents/MacOS/Cling"
cp -R .build/release/Cling_Cling.bundle "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Cling</string>
    <key>CFBundleDisplayName</key><string>Cling</string>
    <key>CFBundleIdentifier</key><string>com.milording.cling</string>
    <key>CFBundleExecutable</key><string>Cling</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHumanReadableCopyright</key><string>© 2026 milording</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf /Applications/Cling.app
    cp -R "$APP" /Applications/Cling.app
    echo "Installed to /Applications/Cling.app"
fi
