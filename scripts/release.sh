#!/bin/bash
set -e

PROJECT_DIR="/workspaces/Edu3"

cd "$PROJECT_DIR"

echo "========================================"
echo "🚀 Edu3 Release Builder"
echo "========================================"

# Java setup
JAVA_BIN=$(which java)
export JAVA_HOME=$(dirname $(dirname $(readlink -f "$JAVA_BIN")))
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using Java:"
java -version

# Flutter setup
export PATH="/home/codespace/flutter/bin:$PATH"

# Android SDK
export ANDROID_HOME="/home/vscode/android-sdk"
export ANDROID_SDK_ROOT="/home/vscode/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Read version
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')

VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$VERSION" | cut -d'+' -f2)

echo ""
echo "Version Name : $VERSION_NAME"
echo "Version Code : $VERSION_CODE"

# local.properties
cat > android/local.properties <<EOF
sdk.dir=/home/vscode/android-sdk
flutter.sdk=/home/codespace/flutter
flutter.buildMode=release
flutter.versionName=$VERSION_NAME
flutter.versionCode=$VERSION_CODE
EOF

echo "✔ local.properties updated"

flutter clean
flutter pub get

echo ""
echo "Building APK..."

flutter build apk --release \
--no-shrink \
--android-skip-build-dependency-validation

mkdir -p release

APK_NAME="VEDO-v${VERSION_NAME}+${VERSION_CODE}.apk"

cp build/app/outputs/flutter-apk/app-release.apk "release/$APK_NAME"

echo ""
echo "========================================"
echo "✅ BUILD SUCCESSFUL"
echo "========================================"

echo "APK:"
echo "release/$APK_NAME"