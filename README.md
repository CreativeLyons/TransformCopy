# TransformCopy

TransformCopy applies a transformation from one node to another image, giving you independent control over each transformation.

## Features

- Copy transformations from any Transform node (CornerPin, Transform, Card3D, etc.) to any image
- Mix different formats and resolutions
- Enhanced transform chain traversal (walks past Blur, Grade, Reformat, etc.)
- Reference frame support for stabilization workflows
- Retime support for matching retimed plates
- Inverse transformation option

## Supported Versions

- **Nuke 15** (Qt5)
- **Nuke 16** (Qt6)

## Supported Architectures

- Apple Silicon (arm64)
- Intel (x86_64)
- Universal2 (both architectures)

## Installation

1. Download the latest release from [GitHub Releases](https://github.com/yourusername/TransformCopy/releases)
2. Extract the zip file
3. Copy the `TransformCopy` folder to `~/.nuke/`
4. Restart Nuke
5. Find TransformCopy in the **Transform** menu, or press **Tab** and type "TransformCopy"

## Usage

Connect your image to input 0, and the transform source (CornerPin, Transform, etc.) to input 1. TransformCopy will apply that transformation to your image.

## Tutorial

<a href="https://youtu.be/viBFhVO5ROQ">Watch the full tutorial video</a>

## Example

<img src="https://github.com/EyalShirazi/Nuke/blob/main/Plugins/TransformCopy/demo/TransformCopy_example01.jpg"/>

## Building from Source

See [BUILD.md](BUILD.md) for build instructions.

## License

See [LICENSE](LICENSE) file.
