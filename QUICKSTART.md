# Quick Start Guide

## Build for Apple Silicon (arm64)

```bash
# Using the build script (recommended)
./build.sh

# Or manually with CMake
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

## Build for Universal (arm64 + x86_64)

```bash
# Using the build script
./build.sh --universal2

# Or manually
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DTRANSFORMCOPY_UNIVERSAL2=ON
cmake --build build
```

## Install

```bash
# Copy plugin to Nuke plugins directory
cp build/TransformCopy.ofx.bundle/Contents/MacOS/TransformCopy.ofx ~/.nuke/plugins/TransformCopy.dylib
```

## Test in Nuke 16

1. Launch Nuke 16
2. Press `X` and type "TransformCopy"
3. Or use Python: `nuke.createNode("TransformCopy")`

## Troubleshooting

**Plugin not found?**
- Check: `ls ~/.nuke/plugins/TransformCopy.dylib`
- Check Nuke console for errors

**Build fails?**
- Specify Nuke path: `./build.sh --nuke-path "/Applications/Nuke16.0v8/Nuke16.0v8.app/Contents/MacOS"`

For detailed information, see [BUILD.md](BUILD.md).
