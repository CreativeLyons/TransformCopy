#!/bin/bash
# TransformCopy - Release Packaging Script
# Creates a zip file ready for GitHub Releases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="${1:-2.0.0}"
RELEASE_NAME="TransformCopy-v${VERSION}-macOS"
TEMP_DIR="$(mktemp -d)"
RELEASE_DIR="${TEMP_DIR}/${RELEASE_NAME}"

echo "============================================"
echo "TransformCopy Release Packaging"
echo "Version: ${VERSION}"
echo "============================================"
echo ""

# Verify dylibs exist and are universal2
echo ">>> Verifying dylibs..."
for NUKE_VER in 15 16; do
    DYLIB="TransformCopy/Nuke${NUKE_VER}/TransformCopy.dylib"
    if [ ! -f "$DYLIB" ]; then
        echo "ERROR: $DYLIB not found!"
        exit 1
    fi
    
    ARCH_INFO=$(lipo -info "$DYLIB")
    if [[ ! "$ARCH_INFO" =~ "x86_64" ]] || [[ ! "$ARCH_INFO" =~ "arm64" ]]; then
        echo "ERROR: $DYLIB is not universal2!"
        echo "  $ARCH_INFO"
        exit 1
    fi
    echo "  ✓ Nuke ${NUKE_VER}: universal2"
done
echo ""

# Create release directory structure
echo ">>> Creating release structure..."
mkdir -p "${RELEASE_DIR}/TransformCopy/Nuke15"
mkdir -p "${RELEASE_DIR}/TransformCopy/Nuke16"
echo ""

# Copy files
echo ">>> Copying files..."
cp TransformCopy/init.py "${RELEASE_DIR}/TransformCopy/"
cp TransformCopy/menu.py "${RELEASE_DIR}/TransformCopy/"
cp TransformCopy/Nuke15/TransformCopy.dylib "${RELEASE_DIR}/TransformCopy/Nuke15/"
cp TransformCopy/Nuke16/TransformCopy.dylib "${RELEASE_DIR}/TransformCopy/Nuke16/"
echo "  ✓ All files copied"
echo ""

# Verify copied files
echo ">>> Verifying copied files..."
for NUKE_VER in 15 16; do
    DYLIB="${RELEASE_DIR}/TransformCopy/Nuke${NUKE_VER}/TransformCopy.dylib"
    ARCH_INFO=$(lipo -info "$DYLIB")
    echo "  Nuke ${NUKE_VER}: $ARCH_INFO"
done
echo ""

# Create zip file
ZIP_FILE="${RELEASE_NAME}.zip"
echo ">>> Creating zip file..."
cd "$TEMP_DIR"
zip -r "${SCRIPT_DIR}/${ZIP_FILE}" "$RELEASE_NAME" > /dev/null
cd "$SCRIPT_DIR"
echo "  ✓ Created: ${ZIP_FILE}"
echo ""

# Verify zip contents
echo ">>> Verifying zip contents..."
unzip -l "$ZIP_FILE" | grep -E "(TransformCopy|\.dylib|\.py)" | head -10
echo ""

# Get file size
FILE_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
echo ">>> Release package ready!"
echo "  File: ${ZIP_FILE}"
echo "  Size: ${FILE_SIZE}"
echo "  Location: ${SCRIPT_DIR}"
echo ""
echo "============================================"
echo "Ready for GitHub Release upload"
echo "============================================"
echo ""
echo "NOTE: Do NOT commit the zip file to git."
echo "      Upload it directly to GitHub Releases."
echo ""

# Cleanup temp directory
rm -rf "$TEMP_DIR"
