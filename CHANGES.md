# Changes Made for Nuke 16 macOS Build

## Summary

This document describes all changes made to build TransformCopy as a macOS plugin for Nuke 16.0v8.

**Important Note**: This is a **DDImage plugin** (not an OFX plugin), which uses Nuke's internal DDImage API. The bundle structure has been created as requested, but DDImage plugins typically just need the `.dylib` file in `~/.nuke/plugins/`.

## Files Added

1. **CMakeLists.txt** - Modern CMake build system
2. **Info.plist.in** - Template for macOS bundle Info.plist
3. **BUILD.md** - Comprehensive build and installation documentation
4. **build.sh** - Convenience build script
5. **CHANGES.md** - This file

## Files Modified

### source/TransformCopy.cpp

**Changes:**
1. Added missing includes:
   - `<sstream>` - for `std::stringstream`
   - `<string>` - for `std::string`
   - `<algorithm>` - for `std::min` and `std::max`

2. Fixed deprecated Qt API:
   - Changed `QString::SkipEmptyParts` to `Qt::SkipEmptyParts` (line 495)
   - This API was deprecated in Qt 5.15+ and removed in Qt 6

**Rationale:**
- The code uses `std::stringstream` but didn't include `<sstream>`
- `QString::SkipEmptyParts` is deprecated and causes warnings/errors with modern Qt
- These changes ensure compatibility with Nuke 16's Qt version

## Build System Changes

### Removed from old Makefile:
- `-msse` flag - Not applicable on Apple Silicon, causes compilation errors
- Manual MOC file generation - Now handled automatically by CMake AUTOMOC
- Hardcoded paths - Now configurable via CMake variables

### Added to CMake:
- C++17 standard (upgraded from C++11)
- Apple Silicon (arm64) support
- Optional universal2 (arm64 + x86_64) support
- Automatic Qt MOC handling
- Proper macOS bundle structure
- RPATH configuration for plugin loading
- Symbol visibility settings for plugin registration

## Architecture Support

- **arm64**: Native for Apple Silicon (M1/M2/M3) - Default
- **universal2**: Supports both Apple Silicon and Intel - Optional via `-DTRANSFORMCOPY_UNIVERSAL2=ON`

## Nuke 16 Specific Compatibility

1. **C++ Standard**: Upgraded to C++17 (Nuke 16 uses modern C++ features)
2. **Qt Version**: Compatible with Qt5 (shipped with Nuke 16)
3. **Symbol Export**: Ensured plugin registration symbols are properly exported
4. **Library Linking**: Links against Nuke 16's DDImage library

## Build Output Structure

The build creates:
```
TransformCopy.ofx.bundle/
├── Contents/
│   ├── Info.plist          (Bundle metadata)
│   └── MacOS/
│       └── TransformCopy.ofx  (Plugin binary, .dylib)
```

**Note**: Despite the `.ofx.bundle` name, this is a DDImage plugin. The bundle structure is provided for compatibility, but the plugin can also be installed as a simple `.dylib` file.

## Plugin Registration

The plugin registers itself using Nuke's DDImage API:
```cpp
static DD::Image::Iop* buildTransformCopyOp(Node* node) {
    return new TransformCopy(node);
}
const DD::Image::Iop::Description TransformCopy::d("TransformCopy", 0, buildTransformCopyOp);
```

This is the standard DDImage plugin registration mechanism, not OFX.

## Testing Checklist

- [ ] Plugin builds successfully for arm64
- [ ] Plugin builds successfully for universal2 (if needed)
- [ ] Plugin loads in Nuke 16 without errors
- [ ] TransformCopy node appears in node creation dialog (press 'X')
- [ ] Node can be created and used in a script
- [ ] All knobs and functionality work as expected

## Known Limitations

1. **MOC File**: The pre-generated `ToggleButtonWidget.moc` file may need regeneration with Nuke 16's Qt version. CMake AUTOMOC should handle this automatically.

2. **Bundle vs. Dylib**: DDImage plugins typically don't use bundle structure. The bundle is created as requested, but the plugin may work better as a simple `.dylib` in `~/.nuke/plugins/`.

3. **Qt Version**: The plugin must be built against the same Qt version that Nuke 16 uses. CMake will find Qt5 automatically if it's in the system path, but Nuke's bundled Qt should be used.

## Future Improvements

1. Consider removing bundle structure if not needed (DDImage plugins work fine as `.dylib` files)
2. Add CI/CD for automated builds
3. Add unit tests if applicable
4. Consider converting to OFX if cross-platform compatibility is needed (would require significant rewrite)
