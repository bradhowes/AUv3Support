![SPM](https://img.shields.io/badge/SPM.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# AUv3Support

Swift package containing useful code for AUv3 app extensions. Included:

- AudioUnitHost -- a simple AUv3 host that loads your AUv3 component and connects it up
- SimplePlayEngine -- a simple AudioUnit graph that plays audio from a file and sends it through the loaded
  component and then to the speaker.
- UserPresetManager -- manager of user presets for an AUv3 component
- Extensions -- various class extensions that makes life easier
- Kernel -- various C++ headers for a kernel that renders audio samples
- Resources -- two audio files that can be played using the `SimplePlayEngine`
- User Interface -- collection of classes that I use to use knobs and switches to control runtime parameters of
  an AUv3 component.

The code works on both iOS and macOS platforms. For now it depends on my [Knob](https://github.com/bradhowes/Knob)
library, though there is no UI component to this library.
