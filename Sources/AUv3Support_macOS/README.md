# macOS Host Support

- `HostViewConfig` -- contains the elements that a macOS main view controller must provide in order to use the
  `HostViewManager` functionality.
- `HostViewManager` -- the core of the hosting environment for the AUv3 audio unit. Pretty much stands in for a `NSViewController`.
- `PresetsMenuManager` -- manages the `NSMenu` items that show the factory and user presets. Works with the
  `UserPresetsManger` in the `AUV3-Support` package to create, update, and delete user presets.
