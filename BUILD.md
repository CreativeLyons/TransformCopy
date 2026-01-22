# Building TransformCopy for Nuke 16 on macOS

## Prerequisites

- macOS (Apple Silicon or Intel)
- CMake 3.20 or later
- Apple Clang (comes with Xcode Command Line Tools)
- Nuke 16.0v8 installed
- Qt5 (typically comes with Nuke, but may need to be found separately)

## Build Instructions

### 1. Configure the build

First, locate your Nuke 16 installation. The default path is:
```
/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS
```

If Nuke is installed elsewhere, you can specify the path:

```bash
# For arm64 only (Apple Silicon)
cmake -B build -S . \
  -DCMAKE_BUILD_TYPE=Release \
  -DNUKE_ROOT_DIR="/path/to/Nuke16.0v8.app/Contents/MacOS"

# For universal2 (arm64 + x86_64)
cmake -B build -S . \
  -DCMAKE_BUILD_TYPE=Release \
  -DNUKE_ROOT_DIR="/path/to/Nuke16.0v8.app/Contents/MacOS" \
  -DTRANSFORMCOPY_UNIVERSAL2=ON
```

### 2. Build the plugin

```bash
cmake --build build --config Release
```

### 3. Output

The build will create:
- `build/TransformCopy.ofx.bundle/` - The complete bundle structure
  - `Contents/Info.plist` - Bundle metadata
  - `Contents/MacOS/TransformCopy.ofx` - The plugin binary (.dylib)

## Installation

### Option 1: Standard DDImage Plugin Installation (Recommended)

DDImage plugins for Nuke are typically installed as simple `.dylib` files:

```bash
# Copy the plugin to your Nuke plugins directory
mkdir -p ~/.nuke/plugins
cp build/TransformCopy.dylib ~/.nuke/plugins/
```

**Note:** The bundle structure is created for compatibility, but Nuke DDImage plugins typically just need the `.dylib` file.

### Option 2: Bundle Installation (OFX-style)

If you want to use the bundle structure:

```bash
# Copy the entire bundle
cp -r build/TransformCopy.ofx.bundle ~/.nuke/plugins/
```

However, Nuke may not automatically discover plugins in bundle format for DDImage plugins. The standard approach (Option 1) is recommended.

## Testing in Nuke 16

1. Launch Nuke 16
2. Press `X` to open the node creation dialog
3. Type "TransformCopy" - the node should appear
4. Alternatively, create it via Python:
   ```python
   nuke.createNode("TransformCopy")
   ```

## Troubleshooting

### Plugin not appearing in Nuke

1. **Check Nuke console for errors:**
   - Open Nuke's Script Editor
   - Look for error messages about plugin loading

2. **Verify plugin path:**
   ```bash
   # Check if the plugin is in the right location
   ls -la ~/.nuke/plugins/TransformCopy.dylib
   ```

3. **Check architecture compatibility:**
   ```bash
   # Verify the binary architecture
   file ~/.nuke/plugins/TransformCopy.dylib
   # Should show: Mach-O 64-bit dynamically linked shared library arm64
   # or: Mach-O universal binary with 2 architectures: [ arm64 x86_64 ]
   ```

4. **Check dependencies:**
   ```bash
   # List linked libraries
   otool -L ~/.nuke/plugins/TransformCopy.dylib
   # Should show libDDImage.dylib and Qt libraries
   ```

### Build Errors

#### "Nuke installation not found"
- Set `NUKE_ROOT_DIR` explicitly:
  ```bash
  cmake -B build -S . -DNUKE_ROOT_DIR="/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS"
  ```

#### "Qt5 not found"
- Nuke ships with Qt5, but CMake might not find it
- You may need to set `Qt5_DIR`:
  ```bash
  cmake -B build -S . -DQt5_DIR="/path/to/qt5/lib/cmake/Qt5"
  ```

#### "Missing symbols" or "Undefined symbols"
- Ensure you're linking against the correct Nuke version's DDImage library
- Check that the Nuke installation is complete

### Runtime Errors

#### "dyld: Library not loaded"
- The plugin can't find required libraries
- Check `otool -L` output
- Ensure Nuke's libraries are accessible (they should be if Nuke runs)

#### Plugin crashes Nuke
- Check Nuke console for detailed error messages
- Verify the plugin was built with the same C++ standard as Nuke 16
- Ensure compatibility with Nuke 16's Qt version

## Architecture Notes

- **arm64**: Native for Apple Silicon Macs (M1/M2/M3)
- **universal2**: Works on both Apple Silicon and Intel Macs (larger binary)

For best performance, use arm64 on Apple Silicon. Use universal2 only if you need to support both architectures.

## Code Changes for Nuke 16 Compatibility

The following changes were made for Nuke 16 compatibility:

1. **Updated Qt API**: Changed `QString::SkipEmptyParts` to `Qt::SkipEmptyParts` (deprecated in Qt 5.15+)
2. **Added missing includes**: Added `<sstream>`, `<string>`, and `<algorithm>` headers
3. **Removed incompatible flags**: Removed `-msse` flag (not applicable on Apple Silicon)
4. **Updated C++ standard**: Set to C++17 (from C++11)
5. **Fixed symbol visibility**: Ensured plugin registration symbols are exported

## Build System

The build uses CMake with the following key features:

- Automatic Qt MOC handling
- Proper macOS bundle structure
- Architecture selection (arm64 or universal2)
- RPATH configuration for plugin loading
- Symbol visibility settings for plugin registration
