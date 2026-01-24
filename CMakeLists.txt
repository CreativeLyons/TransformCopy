cmake_minimum_required(VERSION 3.20)
project(TransformCopy VERSION 2.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# macOS-specific settings
if(APPLE)
    set(CMAKE_MACOSX_RPATH ON)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF)
    set(CMAKE_INSTALL_RPATH "@loader_path")
endif()

# Build options
option(TRANSFORMCOPY_UNIVERSAL2 "Build universal2 binary (arm64+x86_64)" OFF)
set(NUKE_VERSION "" CACHE STRING "Nuke major version to build for (15 or 16)")

# Validate NUKE_VERSION
if(NOT NUKE_VERSION)
    message(FATAL_ERROR "NUKE_VERSION is required. Set -DNUKE_VERSION=15 or -DNUKE_VERSION=16")
endif()
if(NOT NUKE_VERSION MATCHES "^(15|16)$")
    message(FATAL_ERROR "NUKE_VERSION must be 15 or 16. Got: ${NUKE_VERSION}")
endif()

# Architecture settings
if(APPLE AND TRANSFORMCOPY_UNIVERSAL2)
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    message(STATUS "Building universal2 binary (arm64+x86_64)")
elseif(APPLE)
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    message(STATUS "Building arm64 binary")
endif()

# Determine Qt version based on Nuke version
if(NUKE_VERSION STREQUAL "15")
    set(QT_VERSION_MAJOR 5)
    message(STATUS "Nuke 15: Using Qt5")
elseif(NUKE_VERSION STREQUAL "16")
    set(QT_VERSION_MAJOR 6)
    message(STATUS "Nuke 16: Using Qt6")
endif()

# Find Nuke installation based on NUKE_VERSION
# NUKE_ROOT should point to Nuke.app/Contents (not MacOS subdirectory)
if(NOT NUKE_ROOT)
    # Build list of possible Nuke paths for the specified version
    if(NUKE_VERSION STREQUAL "15")
        set(NUKE_ROOT_DEFAULT_PATHS
            "/Applications/Nuke15.2v7/Nuke15.2v7.app/Contents"
            "/Applications/Nuke15.1v6/Nuke15.1v6.app/Contents"
            "/Applications/Nuke15.0v4/Nuke15.0v4.app/Contents"
            "$ENV{HOME}/Applications/Nuke15.2v7/Nuke15.2v7.app/Contents"
        )
    elseif(NUKE_VERSION STREQUAL "16")
        set(NUKE_ROOT_DEFAULT_PATHS
            "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents"
            "/Applications/Nuke16.0v7/Nuke16.0v7.app/Contents"
            "$ENV{HOME}/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents"
        )
    endif()

    # Find Nuke by looking for Frameworks directory
    find_path(NUKE_ROOT
        NAMES Frameworks/QtCore.framework
        PATHS ${NUKE_ROOT_DEFAULT_PATHS}
        NO_DEFAULT_PATH
        DOC "Path to Nuke.app/Contents"
    )

    if(NOT NUKE_ROOT)
        message(WARNING "Nuke ${NUKE_VERSION} installation not found. Please set NUKE_ROOT to Nuke.app/Contents")
        if(NUKE_VERSION STREQUAL "15")
            set(NUKE_ROOT "/Applications/Nuke15.2v7/Nuke15.2v7.app/Contents" CACHE PATH "Path to Nuke.app/Contents")
        else()
            set(NUKE_ROOT "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents" CACHE PATH "Path to Nuke.app/Contents")
        endif()
    endif()
endif()

# Set derived paths
set(NUKE_ROOT_DIR "${NUKE_ROOT}/MacOS")
set(NUKE_FRAMEWORKS_DIR "${NUKE_ROOT}/Frameworks")

message(STATUS "NUKE_ROOT: ${NUKE_ROOT}")
message(STATUS "NUKE_ROOT_DIR (MacOS): ${NUKE_ROOT_DIR}")
message(STATUS "NUKE_FRAMEWORKS_DIR: ${NUKE_FRAMEWORKS_DIR}")

# Verify Nuke installation
if(NOT EXISTS "${NUKE_ROOT_DIR}/libDDImage.dylib")
    message(FATAL_ERROR "libDDImage.dylib not found at ${NUKE_ROOT_DIR}/libDDImage.dylib")
endif()
if(NOT EXISTS "${NUKE_FRAMEWORKS_DIR}/QtCore.framework")
    message(FATAL_ERROR "Nuke's QtCore.framework not found at ${NUKE_FRAMEWORKS_DIR}/QtCore.framework")
endif()

# Force use of Nuke's Qt frameworks ONLY - no Homebrew/system Qt
message(STATUS "=== Forcing use of Nuke's Qt frameworks ===")

# Set Qt framework paths from Nuke
set(QT_FRAMEWORKS_DIR "${NUKE_FRAMEWORKS_DIR}")
set(QT_CORE_FRAMEWORK "${QT_FRAMEWORKS_DIR}/QtCore.framework")
set(QT_WIDGETS_FRAMEWORK "${QT_FRAMEWORKS_DIR}/QtWidgets.framework")
set(QT_GUI_FRAMEWORK "${QT_FRAMEWORKS_DIR}/QtGui.framework")

# Verify Nuke's Qt frameworks exist
if(NOT EXISTS "${QT_CORE_FRAMEWORK}")
    message(FATAL_ERROR "Nuke's QtCore.framework not found at ${QT_CORE_FRAMEWORK}")
endif()
if(NOT EXISTS "${QT_WIDGETS_FRAMEWORK}")
    message(FATAL_ERROR "Nuke's QtWidgets.framework not found at ${QT_WIDGETS_FRAMEWORK}")
endif()
if(NOT EXISTS "${QT_GUI_FRAMEWORK}")
    message(FATAL_ERROR "Nuke's QtGui.framework not found at ${QT_GUI_FRAMEWORK}")
endif()

message(STATUS "Using Nuke's Qt frameworks from: ${QT_FRAMEWORKS_DIR}")

# Set up Qt include directories from Nuke's frameworks
# Qt6 frameworks have Headers directly, not Headers/QtCore
set(QT_CORE_INCLUDE_DIR "${QT_CORE_FRAMEWORK}/Headers")
set(QT_WIDGETS_INCLUDE_DIR "${QT_WIDGETS_FRAMEWORK}/Headers")
set(QT_GUI_INCLUDE_DIR "${QT_GUI_FRAMEWORK}/Headers")

# Also add parent Frameworks directory for framework-style includes
set(QT_FRAMEWORKS_INCLUDE_DIR "${QT_FRAMEWORKS_DIR}")

# Find moc (Qt Meta Object Compiler)
# Nuke doesn't ship moc, so we'll use Homebrew Qt moc
# Note: moc is only used at build time for code generation, not linked into the plugin
# MUST use matching Qt version moc for header compatibility
if(QT_VERSION_MAJOR EQUAL 6)
    # Qt6 moc paths
    find_program(QT_MOC_EXECUTABLE
        NAMES moc
        PATHS "/opt/homebrew/Cellar/qt/*/share/qt/libexec"
              "/opt/homebrew/opt/qt/share/qt/libexec"
              "/opt/homebrew/opt/qt@6/share/qt/libexec"
              "/usr/local/Cellar/qt/*/share/qt/libexec"
        NO_DEFAULT_PATH
    )
    if(NOT QT_MOC_EXECUTABLE)
        find_program(QT_MOC_EXECUTABLE
            NAMES moc-qt6 moc6 moc
            PATHS "/opt/homebrew/opt/qt/bin"
                  "/opt/homebrew/opt/qt@6/bin"
            NO_DEFAULT_PATH
        )
    endif()
    if(NOT QT_MOC_EXECUTABLE)
        find_program(QT_MOC_EXECUTABLE NAMES moc-qt6 moc6 moc)
    endif()
    if(NOT QT_MOC_EXECUTABLE)
        message(FATAL_ERROR "Qt6 MOC not found. Please install Qt6 via Homebrew: brew install qt")
    endif()
elseif(QT_VERSION_MAJOR EQUAL 5)
    # Qt5 moc paths
    find_program(QT_MOC_EXECUTABLE
        NAMES moc
        PATHS "/opt/homebrew/opt/qt@5/bin"
              "/opt/homebrew/Cellar/qt@5/*/bin"
              "/usr/local/opt/qt@5/bin"
        NO_DEFAULT_PATH
    )
    if(NOT QT_MOC_EXECUTABLE)
        find_program(QT_MOC_EXECUTABLE NAMES moc-qt5 moc5 moc)
    endif()
    if(NOT QT_MOC_EXECUTABLE)
        message(FATAL_ERROR "Qt5 MOC not found. Please install Qt5 via Homebrew: brew install qt@5")
    endif()
endif()

message(STATUS "Found Qt${QT_VERSION_MAJOR} MOC: ${QT_MOC_EXECUTABLE}")
# Set MOC executable for AUTOMOC
set(CMAKE_AUTOMOC_EXECUTABLE ${QT_MOC_EXECUTABLE})
set(QT_FOUND TRUE)

# Enable AUTOMOC with explicit MOC executable (we don't use Qt6 CMake targets)
set(CMAKE_AUTOMOC ON)
# Disable AUTORCC and AUTOUIC since we're not using Qt6 CMake targets
set(CMAKE_AUTORCC OFF)
set(CMAKE_AUTOUIC OFF)

# Include directories - ONLY Nuke's headers
# Set these BEFORE creating the target so AUTOMOC can use them
include_directories(
    ${NUKE_ROOT_DIR}/include
    ${QT_CORE_INCLUDE_DIR}
    ${QT_WIDGETS_INCLUDE_DIR}
    ${QT_GUI_INCLUDE_DIR}
)

# Set include paths for AUTOMOC
set(CMAKE_AUTOMOC_MOC_OPTIONS
    "-I${NUKE_ROOT_DIR}/include"
    "-I${QT_CORE_INCLUDE_DIR}"
    "-I${QT_WIDGETS_INCLUDE_DIR}"
    "-I${QT_GUI_INCLUDE_DIR}"
)

message(STATUS "Qt include directories:")
message(STATUS "  Core: ${QT_CORE_INCLUDE_DIR}")
message(STATUS "  Widgets: ${QT_WIDGETS_INCLUDE_DIR}")
message(STATUS "  Gui: ${QT_GUI_INCLUDE_DIR}")

# Source files
set(SOURCES
    source/TransformCopy.cpp
    source/ToggleButtonKnob.h
    source/ToggleButtonWidget.h
)

# Create MODULE library (shared library for plugin)
add_library(TransformCopy MODULE ${SOURCES})

# Create symlinks for <QtCore/...> style includes during configuration
# Qt6 headers internally use <QtCore/qobjectdefs.h>, so we need:
# build/QtCore -> Headers (so <QtCore/qobjectdefs.h> finds Headers/qobjectdefs.h)
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/qt_include_workaround")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink "${QT_CORE_INCLUDE_DIR}" "${CMAKE_BINARY_DIR}/qt_include_workaround/QtCore"
    RESULT_VARIABLE SYMLINK_RESULT
    ERROR_QUIET
)
execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink "${QT_WIDGETS_INCLUDE_DIR}" "${CMAKE_BINARY_DIR}/qt_include_workaround/QtWidgets"
    RESULT_VARIABLE SYMLINK_RESULT2
    ERROR_QUIET
)
execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink "${QT_GUI_INCLUDE_DIR}" "${CMAKE_BINARY_DIR}/qt_include_workaround/QtGui"
    RESULT_VARIABLE SYMLINK_RESULT3
    ERROR_QUIET
)

# Set include directories on target (needed for AUTOMOC-generated files)
target_include_directories(TransformCopy PRIVATE
    ${NUKE_ROOT_DIR}/include
    ${CMAKE_BINARY_DIR}/qt_include_workaround  # For <QtCore/...> includes
    ${QT_CORE_INCLUDE_DIR}
    ${QT_WIDGETS_INCLUDE_DIR}
    ${QT_GUI_INCLUDE_DIR}
)

# Set output name
set_target_properties(TransformCopy PROPERTIES
    OUTPUT_NAME "TransformCopy"
    PREFIX ""
    SUFFIX ".dylib"
)

# Compiler flags
target_compile_options(TransformCopy PRIVATE
    -fPIC
    -Wall
    -Wextra
    -O3
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
)

# Linker flags - allow missing frameworks (for deprecated AGL)
if(APPLE)
    set_target_properties(TransformCopy PROPERTIES
        LINK_FLAGS "-Wl,-undefined,dynamic_lookup"
    )
endif()

# Remove -msse flag (not needed on Apple Silicon, and causes issues)
# Also remove -DUSE_GLEW if not needed (keeping it for compatibility)

# Link libraries - ONLY Nuke's Qt frameworks
# Qt6 requires AGL stub (AGL is deprecated but Qt6 still references it)
if(QT_VERSION_MAJOR EQUAL 6)
    set(AGL_STUB_DIR "${CMAKE_BINARY_DIR}/AGL.framework")
    file(MAKE_DIRECTORY "${AGL_STUB_DIR}")
    file(WRITE "${AGL_STUB_DIR}/Info.plist" "<?xml version=\"1.0\"?><plist><dict><key>CFBundleExecutable</key><string>AGL</string></dict></plist>")
    # Create minimal AGL stub dylib using clang
    file(WRITE "${CMAKE_BINARY_DIR}/agl_stub.c" "void aglDummy() {}\n")
    find_program(CLANG_EXECUTABLE clang)
    if(NOT CLANG_EXECUTABLE)
        set(CLANG_EXECUTABLE "clang")
    endif()
    add_custom_command(OUTPUT "${AGL_STUB_DIR}/AGL"
        COMMAND ${CLANG_EXECUTABLE} -shared -o "${AGL_STUB_DIR}/AGL" "${CMAKE_BINARY_DIR}/agl_stub.c" -install_name "${AGL_STUB_DIR}/AGL"
        DEPENDS "${CMAKE_BINARY_DIR}/agl_stub.c"
        COMMENT "Creating AGL stub framework"
    )
    add_custom_target(agl_stub DEPENDS "${AGL_STUB_DIR}/AGL")
    add_dependencies(TransformCopy agl_stub)
    # Add AGL stub framework search path
    target_link_options(TransformCopy PRIVATE
        "LINKER:-F,${CMAKE_BINARY_DIR}"
    )
endif()

# Link directly to Nuke's Qt frameworks (not via CMake targets to avoid Homebrew Qt)
# Use full framework paths to avoid any search path issues
target_link_libraries(TransformCopy PRIVATE
    ${NUKE_ROOT_DIR}/libDDImage.dylib
    "${QT_CORE_FRAMEWORK}/QtCore"
    "${QT_WIDGETS_FRAMEWORK}/QtWidgets"
    "${QT_GUI_FRAMEWORK}/QtGui"
)

# Set install name and RPATH for macOS
# Use @rpath so plugin resolves Qt from Nuke's Frameworks directory at runtime
if(APPLE)
    set_target_properties(TransformCopy PROPERTIES
        INSTALL_NAME_DIR "@rpath"
        BUILD_WITH_INSTALL_RPATH ON
    )
    # Add RPATH to Nuke's Frameworks directory so Qt resolves correctly
    set_target_properties(TransformCopy PROPERTIES
        INSTALL_RPATH "@loader_path/../../../Frameworks"
        BUILD_WITH_INSTALL_RPATH ON
    )
    # Also add explicit rpath for development/testing
    target_link_options(TransformCopy PRIVATE
        "LINKER:-rpath,${NUKE_FRAMEWORKS_DIR}"
    )
endif()

# Export symbols (needed for plugin registration)
if(APPLE)
    set_target_properties(TransformCopy PROPERTIES
        CXX_VISIBILITY_PRESET default
        VISIBILITY_INLINES_HIDDEN OFF
    )
    target_compile_options(TransformCopy PRIVATE -fvisibility=default)
endif()

# Installation
install(TARGETS TransformCopy
    LIBRARY DESTINATION .
)

# Create bundle structure (optional, for OFX-like packaging)
# Note: DDImage plugins typically just need the .dylib file in ~/.nuke/plugins/
# But we'll create the bundle structure as requested
set(BUNDLE_NAME "TransformCopy.ofx.bundle")
set(BUNDLE_DIR "${CMAKE_BINARY_DIR}/${BUNDLE_NAME}")
set(BUNDLE_CONTENTS_DIR "${BUNDLE_DIR}/Contents")
set(BUNDLE_MACOS_DIR "${BUNDLE_CONTENTS_DIR}/MacOS")

# Create Info.plist
configure_file(
    "${CMAKE_SOURCE_DIR}/Info.plist.in"
    "${BUNDLE_CONTENTS_DIR}/Info.plist"
    @ONLY
)

# Custom target to create bundle
# Also remove AGL framework reference (deprecated, not available on modern macOS)
add_custom_target(bundle ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${BUNDLE_MACOS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:TransformCopy>"
        "${BUNDLE_MACOS_DIR}/TransformCopy.ofx"
    COMMAND install_name_tool -delete_rpath "/System/Library/Frameworks/AGL.framework" "${BUNDLE_MACOS_DIR}/TransformCopy.ofx" 2>/dev/null || true
    DEPENDS TransformCopy
    COMMENT "Creating ${BUNDLE_NAME} bundle"
)

# Print build information
message(STATUS "")
message(STATUS "=== TransformCopy Build Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Nuke version: ${NUKE_VERSION}")
message(STATUS "Architecture: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "Nuke root: ${NUKE_ROOT_DIR}")
message(STATUS "Qt version: ${QT_VERSION_MAJOR} (from Nuke's bundled frameworks)")
message(STATUS "Qt frameworks path: ${QT_FRAMEWORKS_DIR}")
message(STATUS "Output: ${BUNDLE_NAME}")
message(STATUS "==========================================")
message(STATUS "")
