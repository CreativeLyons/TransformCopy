#!/bin/bash
# Build script for TransformCopy plugin for Nuke 16 on macOS

set -e  # Exit on error

# Default values
BUILD_TYPE="Release"
ARCH="arm64"
NUKE_PATH=""
UNIVERSAL2=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nuke-path)
            NUKE_PATH="$2"
            shift 2
            ;;
        --universal2)
            UNIVERSAL2=true
            ARCH="universal2"
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --nuke-path PATH    Path to Nuke installation (e.g., /Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS)"
            echo "  --universal2        Build universal2 binary (arm64 + x86_64)"
            echo "  --debug             Build in Debug mode (default: Release)"
            echo "  --help              Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Try to find Nuke if not specified
if [ -z "$NUKE_PATH" ]; then
    POSSIBLE_PATHS=(
        "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS"
        "$HOME/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS"
    )

    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path/libDDImage.dylib" ]; then
            NUKE_PATH="$path"
            break
        fi
    done

    if [ -z "$NUKE_PATH" ]; then
        echo "Error: Nuke installation not found."
        echo "Please specify --nuke-path or install Nuke 16.0v8 in a standard location."
        exit 1
    fi
fi

echo "=========================================="
echo "TransformCopy Build Script"
echo "=========================================="
echo "Build type: $BUILD_TYPE"
echo "Architecture: $ARCH"
echo "Nuke path: $NUKE_PATH"
echo "=========================================="
echo ""

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Configure CMake
CMAKE_ARGS=(
    -B "$BUILD_DIR"
    -S .
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    -DNUKE_ROOT_DIR="$NUKE_PATH"
)

if [ "$UNIVERSAL2" = true ]; then
    CMAKE_ARGS+=(-DTRANSFORMCOPY_UNIVERSAL2=ON)
fi

echo "Configuring CMake..."
cmake "${CMAKE_ARGS[@]}"

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE"

# Check output
BUNDLE_PATH="$BUILD_DIR/TransformCopy.ofx.bundle"
if [ -d "$BUNDLE_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "Build successful!"
    echo "=========================================="
    echo "Bundle location: $BUNDLE_PATH"
    echo ""
    echo "To install:"
    echo "  cp -r $BUNDLE_PATH ~/.nuke/plugins/"
    echo ""
    echo "Or just the plugin binary:"
    echo "  cp $BUNDLE_PATH/Contents/MacOS/TransformCopy.ofx ~/.nuke/plugins/TransformCopy.dylib"
    echo ""
else
    echo "Error: Bundle not found at $BUNDLE_PATH"
    exit 1
fi
