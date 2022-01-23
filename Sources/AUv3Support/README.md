# Support

Collection of additional utilities that make life easier when working with AUv3 and Swift.

- [AudioUnitHost](AudioUnitHost.swift) -- mimics a very minimal AUv3 host by instantiating the AUv3 plugin
  and showing its control view. It also provides a way to save and restore AUv3 state between app launches.

- [Logging](Logging.swift) -- implements my own way of partitioning log statements

- [UserPresetManager](UserPresetManager.swift) -- manages the presets for an AUv3 component.

- [Audio](Audio) -- holds an audio file that is used by the app to demonstrate the AUv3 effect. Also contains
  [SimplePlayEngine](Audio/SimplePlayEngine.swift) (based on Apple code) that creates a simple audio graph
  consisting of an `AVAudioPlayerNode` that plays the sample file and the AUv3 effect node, with the sample
  audio going into the effect and the effect connected to device's audio output.

- [Extensions](Extensions) -- useful extensions to various Apple classes to simply the code

- [Kernel][Kernel] -- useful C++ definitions for a C++ kernel that performs the sample rendering of an AUv3 component
