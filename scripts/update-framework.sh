#!/bin/bash
# Update C2PAC.xcframework from c2pa-rs releases
# Usage: ./scripts/update-framework.sh v0.73.0

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v0.73.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_ROOT/build-temp"
FRAMEWORK_DIR="$REPO_ROOT/Frameworks"

echo "Updating to c2pa-rs $VERSION..."

# Clean up
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

# Download binaries
echo "Downloading iOS binaries..."
gh release download "c2pa-$VERSION" --repo contentauth/c2pa-rs \
    --pattern "c2pa-$VERSION-aarch64-apple-ios.zip" \
    --pattern "c2pa-$VERSION-aarch64-apple-ios-sim.zip" \
    --pattern "c2pa-$VERSION-x86_64-apple-ios.zip"

# Extract
echo "Extracting..."
unzip -q "c2pa-$VERSION-aarch64-apple-ios.zip" -d ios-arm64
unzip -q "c2pa-$VERSION-aarch64-apple-ios-sim.zip" -d ios-sim-arm64
unzip -q "c2pa-$VERSION-x86_64-apple-ios.zip" -d ios-sim-x64

# Create fat binary for simulator
echo "Creating fat binary..."
mkdir -p simulator headers
cp ios-arm64/include/c2pa.h headers/
cat > headers/module.modulemap << 'EOF'
module C2PAC {
    header "c2pa.h"
    export *
}
EOF

lipo -create \
    ios-sim-arm64/lib/libc2pa_c.a \
    ios-sim-x64/lib/libc2pa_c.a \
    -output simulator/libc2pa_c.a

# Remove old framework
rm -rf "$FRAMEWORK_DIR/C2PAC.xcframework"

# Create xcframework
echo "Creating xcframework..."
xcodebuild -create-xcframework \
    -library ios-arm64/lib/libc2pa_c.a -headers headers/ \
    -library simulator/libc2pa_c.a -headers headers/ \
    -output "$FRAMEWORK_DIR/C2PAC.xcframework"

# Strip symbols
echo "Stripping symbols..."
strip -S "$FRAMEWORK_DIR/C2PAC.xcframework/ios-arm64/libc2pa_c.a" || true
strip -S "$FRAMEWORK_DIR/C2PAC.xcframework/ios-arm64_x86_64-simulator/libc2pa_c.a" || true

# Clean up build directory
rm -rf "$BUILD_DIR"

echo "Done! Updated to c2pa-rs $VERSION"
echo "Framework size: $(du -sh "$FRAMEWORK_DIR/C2PAC.xcframework" | cut -f1)"
