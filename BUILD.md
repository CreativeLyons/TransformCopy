# Building TransformCopy for Nuke 15 & 16 on macOS

## Prerequisites

- macOS (Apple Silicon or Intel)
- CMake 3.20 or later
- Apple Clang (comes with Xcode Command Line Tools)
- Nuke 15.2v7 or Nuke 16.0v8 installed
- Qt5 MOC (for Nuke 15) or Qt6 MOC (for Nuke 16) - install via Homebrew: `brew install qt@5 qt`

## Quick Build

Use the automated build script:

```bash
./build_all.sh
```

This builds universal2 binaries for both Nuke 15 and 16.

## Manual Build Instructions

### Build for Nuke 15

```bash
mkdir -p build_nuke15_universal2 && cd build_nuke15_universal2
cmake .. -DNUKE_VERSION=15 -DTRANSFORMCOPY_UNIVERSAL2=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cp TransformCopy.dylib ../TransformCopy/Nuke15/
```

### Build for Nuke 16

```bash
mkdir -p build_nuke16_universal2 && cd build_nuke16_universal2
cmake .. -DNUKE_VERSION=16 -DTRANSFORMCOPY_UNIVERSAL2=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cp TransformCopy.dylib ../TransformCopy/Nuke16/
```

### Build Options

- `NUKE_VERSION`: Set to `15` or `16` (required)
- `TRANSFORMCOPY_UNIVERSAL2`: Set to `ON` for universal2 (arm64 + x86_64), `OFF` for arm64 only
- `CMAKE_BUILD_TYPE`: `Release` (recommended) or `Debug`

## Installation

The `TransformCopy/` folder contains everything needed:

1. Copy the `TransformCopy` folder to `~/.nuke/`
2. Restart Nuke
3. Find TransformCopy in the **Transform** menu, or press **Tab** and type "TransformCopy"

The plugin structure:
```
TransformCopy/
├── init.py          (loads correct version by Nuke major)
├── menu.py          (adds to Transform menu)
├── Nuke15/
│   └── TransformCopy.dylib (universal2)
└── Nuke16/
    └── TransformCopy.dylib (universal2)
```

## Testing

1. Launch Nuke 15 or 16
2. Press `X` to open the node creation dialog
3. Type "TransformCopy" - the node should appear
4. Or find it in the Transform menu
5. Create a node and verify it works

## Troubleshooting

### Plugin not appearing in Nuke

1. **Check Nuke console for errors:**
   - Open Nuke's Script Editor
   - Look for error messages about plugin loading

2. **Verify plugin path:**
   ```bash
   ls -la ~/.nuke/TransformCopy/Nuke15/TransformCopy.dylib
   ```

3. **Check architecture compatibility:**
   ```bash
   lipo -info ~/.nuke/TransformCopy/Nuke15/TransformCopy.dylib
   # Should show: Architectures in the fat file: ... are: x86_64 arm64
   ```

4. **Check dependencies:**
   ```bash
   otool -L ~/.nuke/TransformCopy/Nuke15/TransformCopy.dylib | grep Qt
   # Should show @rpath/QtCore.framework/..., NO /opt/homebrew paths
   ```

### Build Errors

#### "Nuke installation not found"
- CMake will search common locations, but you can specify:
  ```bash
  cmake .. -DNUKE_VERSION=15 -DNUKE_ROOT="/Applications/Nuke15.2v7/Nuke15.2v7.app/Contents"
  ```

#### "Qt MOC not found"
- Install Qt via Homebrew:
  ```bash
  brew install qt@5 qt  # qt@5 for Nuke 15, qt for Nuke 16
  ```

#### "Missing symbols" or linking errors
- Ensure you're linking against the correct Nuke version's DDImage library
- Verify the Nuke installation is complete

### Runtime Errors

#### "dyld: Library not loaded" or symbol errors
- Check `otool -L` output - should show `@rpath` paths, not `/opt/homebrew`
- The plugin must use Nuke's bundled Qt, not Homebrew Qt

## Architecture Support

- **arm64**: Native for Apple Silicon Macs (M1/M2/M3)
- **x86_64**: Intel Macs
- **universal2**: Both architectures in one binary (recommended for releases)

## Build System Details

The build uses CMake with:
- Multi-Nuke version support (NUKE_VERSION parameter)
- Automatic Qt version detection (Qt5 for Nuke 15, Qt6 for Nuke 16)
- Automatic Qt MOC handling
- Universal2 binary support
- RPATH configuration for plugin loading
- Symbol visibility settings for plugin registration
- AGL framework stub (for Qt6 compatibility)

## Change History

### v2.0.0 - Nuke 15 & 16 Support

**Major Changes:**
- Added support for Nuke 15 (Qt5) and Nuke 16 (Qt6)
- Multi-Nuke build system with automatic Qt version detection
- Universal2 binaries for both versions
- Fixed handle drawing bug (input 1 handles no longer double-transform)
- Enhanced transform chain traversal (walks past Blur, Grade, Reformat, Dot, NoOp, Card3D)
- Added chain depth control knob

**Code Changes:**
- Updated `source/TransformCopy.cpp`:
  - Fixed handle drawing in `build_handles()` override
  - Added `is_geometry_affecting()` helper function
  - Enhanced `get_homography()` to walk transform chains
  - Updated `set_transformation_data()` to search chains
  - Added `kChainDepthLimit` knob for user control
- Updated `CMakeLists.txt`:
  - Added `NUKE_VERSION` parameter (15 or 16)
  - Automatic Qt5/Qt6 detection based on Nuke version
  - Universal2 build support
  - AGL framework stub for Qt6

**Files Added:**
- `build_all.sh` - Automated build script
- `package_release.sh` - Release packaging script
- `TransformCopy/init.py` - Plugin loader
- `TransformCopy/menu.py` - Menu registration

**Build System:**
- C++17 standard
- CMake 3.20+ required
- Uses Nuke's bundled Qt frameworks (not Homebrew Qt)
- Creates universal2 binaries by default

### Previous Changes (Nuke 16 Initial Support)

**Code Changes:**
- Updated Qt API: Changed `QString::SkipEmptyParts` to `Qt::SkipEmptyParts` (deprecated in Qt 5.15+)
- Added missing includes: `<sstream>`, `<string>`, `<algorithm>`
- Removed incompatible flags: `-msse` flag (not applicable on Apple Silicon)
- Updated C++ standard: Set to C++17 (from C++11)
- Fixed symbol visibility: Ensured plugin registration symbols are exported

**Important Note**: This is a **DDImage plugin** (not an OFX plugin), which uses Nuke's internal DDImage API. The plugin registers using `DD::Image::Iop::Description`.

## Known Limitations

1. **Qt MOC**: Nuke doesn't ship `moc`, so Homebrew Qt MOC is used at build time (not linked into plugin)
2. **AGL Framework**: Qt6 references deprecated AGL framework - handled with a stub
3. **Transform Chain**: Non-linear warps (SplineWarp, GridWarp, etc.) stop chain traversal

## Future Improvements

- Consider CI/CD for automated builds
- Add unit tests if applicable
- Support for additional Nuke versions as needed
