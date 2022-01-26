![Swift](https://img.shields.io/badge/Swift-5.5-red.svg)
![SPM](https://img.shields.io/badge/SPM-5.5-red.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# AUv3SupportPackage

Swift package containing useful code for AUv3 app extensions. There are three products so far:

- AUv3-Support-Static -- collection of extensions and classes for both the AudioUnit components that is packaged
  as an AUv3 app extension and the host app that contains it. Because it will be linked to the AUv3 app
  extension, it must not link to or use any APIs that are forbidden by Apple for use by app extensions.
  This code works on both iOS and macOS platforms.
- AUv3-Support-iOS -- classes that provide a simple AUv3 hosting environment for the AUv3 app extension.
  Provides an audio chain that sends a sample loop through the AUv3 audio unit and out to the speaker. Also
  provides for user preset management.
- AUv3-Support-macOS -- similar to the above but for macOS. Unfortunately, the setup is not as straightfoward on
  macOS as it is for iOS. So far I have not been able to get a good load from a storyboard held in this package:
  menu items not connected to delegate slots, toolbar buttons not connected to the window.

In the AUv3-Suport-Static product:

- AudioUnitLoader -- a basic AUv3 host that locates your AUv3 component and connects it up
- SimplePlayEngine -- a simple AudioUnit graph that plays audio from a file and sends it through the loaded
  component and then to the speaker.
- UserPresetManager -- manages the user presets of an AUv3 component
- Extensions -- various class extensions that makes life easier
- Resources -- two audio files that can be played using the `SimplePlayEngine`
