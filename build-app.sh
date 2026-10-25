#!/bin/sh
# Build ClipKeep.app into ./dist. Usage: ./build-app.sh [--install]  (--install copies it to ~/Applications)
set -eu
cd "$(dirname "$0")"

swift build -c release
APP=dist/ClipKeep.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ClipKeep "$APP/Contents/MacOS/ClipKeep"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>local.clipkeep</string>
    <key>CFBundleName</key><string>ClipKeep</string>
    <key>CFBundleExecutable</key><string>ClipKeep</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

# Ad-hoc signature: enough to run locally, not for distributing to other Macs.
codesign --force --sign - "$APP"
echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
    mkdir -p ~/Applications
    rm -rf ~/Applications/ClipKeep.app
    cp -R "$APP" ~/Applications/
    echo "Installed ~/Applications/ClipKeep.app"
fi
