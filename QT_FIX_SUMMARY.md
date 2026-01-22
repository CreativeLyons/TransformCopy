# Qt Framework Fix Summary

## Problem
The plugin was linking against Homebrew Qt (6.7.3) instead of Nuke's bundled Qt, causing symbol mismatch errors at runtime:
```
dlopen(.../TransformCopy.dylib): Symbol not found: __Z13comparesEqualRK9QTimeZoneS1_
```

## Solution Implemented

### CMakeLists.txt Changes

1. **Set NUKE_ROOT variable** pointing to `Nuke.app/Contents`:
   ```cmake
   set(NUKE_ROOT "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents")
   set(NUKE_ROOT_DIR "${NUKE_ROOT}/MacOS")
   set(NUKE_FRAMEWORKS_DIR "${NUKE_ROOT}/Frameworks")
   ```

2. **Removed find_package(Qt6)** - No longer searches for system Qt
3. **Direct framework linking** - Links directly to Nuke's Qt frameworks:
   ```cmake
   target_link_libraries(TransformCopy PRIVATE
       ${NUKE_ROOT_DIR}/libDDImage.dylib
       -F${QT_FRAMEWORKS_DIR}
       -framework QtCore
       -framework QtWidgets
       -framework QtGui
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

5. **Include directories** - Only Nuke's Qt headers:
   ```cmake
   target_include_directories(TransformCopy PRIVATE
       ${NUKE_ROOT_DIR}/include
       ${QT_CORE_INCLUDE_DIR}      # Nuke's QtCore.framework/Headers
       ${QT_WIDGETS_INCLUDE_DIR}    # Nuke's QtWidgets.framework/Headers
       ${QT_GUI_INCLUDE_DIR}        # Nuke's QtGui.framework/Headers
   )
   ```

## Remaining Issue: MOC Compatibility

**Problem**: Qt5 moc (from Homebrew) generates code incompatible with Qt6 headers. The generated code uses `QT_INIT_METAOBJECT` which doesn't exist in Qt6.

**Current Status**: Build fails during MOC compilation.

**Solutions**:
1. Install Qt6 moc: `brew install qt` (should provide Qt6 moc)
2. Use pre-generated MOC file (needs updating for Qt6)
3. Manually create MOC file compatible with Qt6

## Verification Commands

Once build succeeds, verify:

```bash
# Check for Homebrew Qt references (should show nothing)
otool -L build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -E "(homebrew|/opt)"

# Check Qt framework paths (should show Nuke paths or @rpath)
otool -L build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -i qt

# Check RPATH entries
otool -l build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx | grep -A 2 "LC_RPATH"
```

## Expected Output

**Before fix:**
```
/opt/homebrew/opt/qt/lib/QtWidgets.framework/Versions/A/QtWidgets
/opt/homebrew/opt/qt/lib/QtGui.framework/Versions/A/QtGui
/opt/homebrew/opt/qt/lib/QtCore.framework/Versions/A/QtCore
```

**After fix:**
```
@rpath/QtWidgets.framework/Versions/A/QtWidgets
@rpath/QtGui.framework/Versions/A/QtGui
@rpath/QtCore.framework/Versions/A/QtCore
```
OR paths pointing to Nuke's Frameworks directory.

## Next Steps

1. Install Qt6 moc: `brew install qt` (if not already installed)
2. Clean rebuild: `rm -rf build && cmake -B build -S . -DNUKE_ROOT="/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents"`
3. Build: `cmake --build build --config Release`
4. Verify: Run the verification commands above
5. Test in Nuke 16
