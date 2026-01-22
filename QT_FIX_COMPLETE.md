# Qt Framework Fix - COMPLETE ✓

## Problem Solved
The plugin was linking against Homebrew Qt (6.7.3) instead of Nuke's bundled Qt, causing symbol mismatch errors:
```
dlopen(.../TransformCopy.dylib): Symbol not found: __Z13comparesEqualRK9QTimeZoneS1_
```

## Solution Implemented

### Key Changes to CMakeLists.txt

1. **NUKE_ROOT variable** - Points to `Nuke.app/Contents`:
   ```cmake
   set(NUKE_ROOT "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents")
   set(NUKE_ROOT_DIR "${NUKE_ROOT}/MacOS")
   set(NUKE_FRAMEWORKS_DIR "${NUKE_ROOT}/Frameworks")
   ```

2. **Removed find_package(Qt6)** - No longer searches for system/Homebrew Qt

3. **Direct framework linking** - Links to Nuke's Qt frameworks using full paths:
   ```cmake
   target_link_libraries(TransformCopy PRIVATE
       ${NUKE_ROOT_DIR}/libDDImage.dylib
       "${QT_CORE_FRAMEWORK}/QtCore"
       "${QT_WIDGETS_FRAMEWORK}/QtWidgets"
       "${QT_GUI_FRAMEWORK}/QtGui"
   )
   ```

4. **RPATH configuration** - Ensures runtime resolution uses Nuke's Qt:
   ```cmake
   set_target_properties(TransformCopy PROPERTIES
       INSTALL_RPATH "@loader_path/../../../Frameworks"
       BUILD_WITH_INSTALL_RPATH ON
   )
   target_link_options(TransformCopy PRIVATE
       "LINKER:-rpath,${NUKE_FRAMEWORKS_DIR}"
   )
   ```

5. **Qt6 MOC** - Uses Qt6 moc from Homebrew (build-time only, not linked):
   ```cmake
   find_program(QT_MOC_EXECUTABLE
       NAMES moc
       PATHS "/opt/homebrew/Cellar/qt/*/share/qt/libexec"
   )
   ```

## Verification Results

### Before Fix:
```
/opt/homebrew/opt/qt/lib/QtWidgets.framework/Versions/A/QtWidgets
/opt/homebrew/opt/qt/lib/QtGui.framework/Versions/A/QtGui
/opt/homebrew/opt/qt/lib/QtCore.framework/Versions/A/QtCore
```

### After Fix:
```
@rpath/QtCore.framework/Versions/A/QtCore (compatibility version 6.0.0, current version 6.5.3)
@rpath/QtWidgets.framework/Versions/A/QtWidgets (compatibility version 6.0.0, current version 6.5.3)
@rpath/QtGui.framework/Versions/A/QtGui (compatibility version 6.0.0, current version 6.5.3)
```

### Verification Commands:
```bash
# Check for Homebrew Qt (should show nothing)
otool -L build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -E "(homebrew|/opt)"

# Check Qt paths (should show @rpath or Nuke paths)
otool -L build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -i qt

# Check RPATH
otool -l build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -A 2 "LC_RPATH"
```

**Result**: ✓ PASSED - No Homebrew Qt references found!

## Clean Rebuild Instructions

```bash
# 1. Clean build directory
rm -rf build

# 2. Configure with NUKE_ROOT
cmake -B build -S . \
  -DCMAKE_BUILD_TYPE=Release \
  -DNUKE_ROOT="/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents"

# 3. Build
cmake --build build --config Release

# 4. Verify (should show @rpath, no /opt/homebrew)
otool -L build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -E "(Qt|homebrew|opt)"

# 5. Install
cp -r build/TransformCopy.ofx.bundle ~/.nuke/plugins/
# OR just the binary:
cp build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx ~/.nuke/plugins/TransformCopy.dylib

# 6. Test in Nuke 16
# Launch Nuke 16, press 'X', type "TransformCopy"
# Or: nuke.createNode("TransformCopy")
```

## Files Modified

1. **CMakeLists.txt** - Complete rewrite of Qt discovery and linking
2. **source/ToggleButtonWidget.h** - Updated includes for Qt6 compatibility

## Success Criteria Met

- ✓ `otool -L` shows zero `/opt/homebrew/Cellar/qt/...` paths
- ✓ Qt frameworks use `@rpath` (resolves from Nuke's Frameworks at runtime)
- ✓ RPATH correctly set to Nuke's Frameworks directory
- ✓ Plugin builds successfully
- ✓ Ready for testing in Nuke 16
