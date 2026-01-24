#!/bin/bash
# TransformCopy - Build All Script
# Builds universal2 binaries for Nuke 15 and Nuke 16

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "TransformCopy - Build All (macOS universal2)"
echo "============================================"
echo ""

# Function to build for a specific Nuke version
build_nuke() {
    local NUKE_VER=$1
    local BUILD_DIR="build_nuke${NUKE_VER}_universal2"
    local OUTPUT_DIR="TransformCopy/Nuke${NUKE_VER}"
    
    echo ">>> Building for Nuke ${NUKE_VER}..."
    
    # Clean and create build directory
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Configure
    cd "$BUILD_DIR"
    cmake .. -DNUKE_VERSION=$NUKE_VER -DTRANSFORMCOPY_UNIVERSAL2=ON -DCMAKE_BUILD_TYPE=Release
    
    # Build
    cmake --build . --config Release -j$(sysctl -n hw.ncpu)
    
    # Verify
    echo ""
    echo ">>> Verifying Nuke ${NUKE_VER} build:"
    lipo -info TransformCopy.dylib
    otool -L TransformCopy.dylib | grep Qt
    
    # Copy to output
    cp TransformCopy.dylib "../$OUTPUT_DIR/TransformCopy.dylib"
    
    cd ..
    echo ""
    echo ">>> Nuke ${NUKE_VER} build complete: $OUTPUT_DIR/TransformCopy.dylib"
    echo ""
}

# Build for both Nuke versions
build_nuke 15
build_nuke 16

echo "============================================"
echo "Build Complete!"
echo "============================================"
echo ""
echo "Output structure:"
find TransformCopy -type f -exec ls -la {} \;
echo ""
echo "Installation:"
echo "  Copy the 'TransformCopy' folder to ~/.nuke/"
echo ""
