[![CI](https://github.com/bradhowes/AUv3Support/actions/workflows/CI.yml/badge.svg)](https://github.com/bradhowes/AUv3Support/actions/workflows/CI.yml)
![Swift](https://img.shields.io/badge/Swift-5.5-red.svg)
![SPM](https://img.shields.io/badge/SPM-5.5-red.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# Overview

Swift package containing useful code for AUv3 app extensions. There are three products so far in this package:

- AUv3-Support -- collection of extensions and classes for both the AudioUnit components that is packaged
  as an AUv3 app extension and the host app that contains it. Because it will be linked to the AUv3 app
  extension, it must not link to or use any APIs that are forbidden by Apple for use by app extensions.
  This code works on both iOS and macOS platforms.
- AUv3-Support-iOS -- classes that provide a simple AUv3 hosting environment for the AUv3 app extension.
  Provides an audio chain that sends a sample loop through the AUv3 audio unit and out to the speaker. Also
  provides for user preset management.
- AUv3-Support-macOS -- similar to the above but for macOS. Unfortunately, the setup is not as straight-forward on
  macOS as it is for iOS. So far I have not been able to get a good load from a storyboard held in this package:
  menu items not connected to delegate slots, toolbar buttons not connected to the window.

These libraries are now being used by my [SimplyFlange](https://github.com/bradhowes/SimplyFlange), 
[SimplyPhaser](https://github.com/bradhowes/SimplyPhaser), and
[AUv3Template](https://github.com/bradhowes/AUv3Template) projects.

# AUv3Support

In the AUv3-Support product you will find various classes and extensions to make things easier when working with AUv3
components:

- Editors -- a collection of parameter editors that work on iOS and macOS via protocol conformance. They properly 
update themselves when a audio unit loads a preset, and they properly communicate changes made by the user or by 
another control, perhaps external. There is a 
`BooleanParameterEditor` that works with a UISwitch/NSSwitch control, and there is a `FloatParameterEditor` that works 
with anything that can report out a floating-point value as well as the min/max ranges the value may have.
- AudioUnitLoader -- a basic AUv3 host that locates your AUv3 component and connects it up
- SimplePlayEngine -- a simple AudioUnit graph that plays audio from a file and sends it through the loaded
  component and then to the speaker.
- UserPresetManager -- manages the user presets of an AUv3 component
- Extensions -- folder with sundry extensions that makes life better
- Resources -- audio files that can be played using the `SimplePlayEngine`. Useful when demoing a filter.

# AUv3Support-iOS

Contains most of what is needed for a simple AUv3 host that will load your AUv3 component, show its UI controls, and 
allow you to play audio through it. The basics for getting it to work are:

1. Create a `HostViewConfig` that contains values specific to your AUv3 component and then pass it to the
`Shared.embedHostView` static function along with your app's main `UIViewController` instance.
2. Modify your `AppDelegate.swift` file to inherit from the AppDelegate found in this package. Something like this is
good:
```
import UIKit
import AUv3Support
import AUv3Support_iOS
import os.log

@main
final class AppDelegate: AUv3Support_iOS.AppDelegate {
  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log: OSLog = Shared.logger(Bundle.main.auBaseName + "Host", "AppDelegate")
}
```
3. Modify your `MainViewController.swift` to do the following:
```
import AUv3Support
import AUv3Support_iOS
import CoreAudioKit
import UIKit

final class MainViewController: UIViewController {

  private var hostViewController: HostViewController!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }

    let bundle = Bundle.main
    let component = AudioComponentDescription(componentType: bundle.auComponentType,
                                              componentSubType: bundle.auComponentSubtype,
                                              componentManufacturer: bundle.auComponentManufacturer,
                                              componentFlags: 0, componentFlagsMask: 0)

    let config = HostViewConfig(name: bundle.auBaseName, version: bundle.releaseVersionNumber,
                                appStoreId: bundle.appStoreId,
                                componentDescription: component, sampleLoop: .sample1) { url in
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    let hostViewController = Shared.embedHostView(into: self, config: config)
    delegate.setStopPlayingBlock { hostViewController.stopPlaying() }
    self.hostViewController = hostViewController
  }
}
```
4. Profit!

The `Actions` folder contains flows for managing user presets such as creating, deleting and renaming. The `HostView` 
storyboard holds a set of UI elements that are useful for a AUv3 demonstration app.

# AUv3Support-macOS

Unlike the above, macOS is a bit more involved because I have yet to get something simpler up and running. The big issue
is getting the application's delegate, main window, and main view controller all established and functional when 
unpacked from a package. So, until that is accomplished, one must pass a bucket-load of UI elements in a 
`HostViewConfig` and instantiate a `HostViewManager` with it. This should be done as early as possible, but it cannot be
done before the main view controller has a window assigned to it. So, the best option is to do something like below, 
where we monitor for a window being set on the view. The only remaining task is to show the initial prompt to the user
on first-time launch.

```
  override func viewDidLoad() {
    super.viewDidLoad()

    // When the window appears, we should be able to access all of the items from the storyboard.
    windowObserver = view.observe(\.window) { _, _ in self.makeHostViewManager() }
  }

  func makeHostViewManager() {
    guard let appDelegate = appDelegate,
          appDelegate.presetsMenu != nil,
          let windowController = windowController
    else {
      fatalError()
    }

    let bundle = Bundle.main
    let audioUnitName = bundle.auBaseName
    let componentDescription = AudioComponentDescription(componentType: bundle.auComponentType,
                                                         componentSubType: bundle.auComponentSubtype,
                                                         componentManufacturer: bundle.auComponentManufacturer,
                                                         componentFlags: 0, componentFlagsMask: 0)
    let config = HostViewConfig(componentName: audioUnitName, componentDescription: componentDescription,
                                sampleLoop: .sample1,
                                playButton: windowController.playButton,
                                bypassButton: windowController.bypassButton,
                                presetsButton: windowController.presetsButton,
                                playMenuItem: appDelegate.playMenuItem,
                                bypassMenuItem: appDelegate.bypassMenuItem,
                                presetsMenu: appDelegate.presetsMenu,
                                viewController: self, containerView: containerView)
    hostViewManager = .init(config: config)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    hostViewManager?.showInitialPrompt()
  }
```

Not great, but not too cumbersome to use now. And it is nice to have abstracted out all of the common functionality my 
audio unit apps share.

# Usage Notes

The packages here build just fine, and they work as-is when they direct dependencies to either other Swift packages or
targets in an Xcode project that are *not* frameworks. When they *are* linked to a framework, there may be issues that 
crop up which will break the build (not clear on the exact conditions). In my particular case with AUv3 app extensions, 
the result was that the common framework that is shared between the app extension and the host app will embed within it 
a Swift package dependency that is also present at the top-level of the host app. Apple rightly flags the duplication 
(plus some other issues) and refuses to upload the archive artifacts.

The solution that works _for me_ was to have a Bash script run after the build step that deletes the embedded 
frameworks. Sounds scary, but it works and Apple likes what it sees. More importantly, the apps run just fine on iOS 
and macOS after this framework culling. Note again and well: if you use these directly with an app extension or app 
target then you should not have any issues.

Here is the script I use; it works for both macOS and iOS 
projects: (`post-build.sh`):

```
#!/bin/bash
set -eu

echo "-- BEGIN post-build.sh"

function process # TOP EMBED
{
    local TOP="${1}" EMBED="${2}"

    cd "${CODESIGNING_FOLDER_PATH}/${TOP}"
    ls -l

    for DIR in *; do
        BAD="${DIR}${EMBED}"
        if [[ -d "${BAD}" ]]; then
            echo "-- deleting '${BAD}'"
            rm -rf "${BAD}"
        fi
    done
}

if [[ -d "${CODESIGNING_FOLDER_PATH}/Contents/Frameworks" ]]; then
    # macOS paths
    process "/Contents/Frameworks" "/Versions/A/Frameworks"
elif [[ -d "${CODESIGNING_FOLDER_PATH}/Frameworks" ]]; then
    # iOS paths
    process "/Frameworks" "/Frameworks"
fi

echo "-- END post-build.sh"
```

To use, edit the Xcode scheme that builds your application (iOS or macOS). Click on the disclosure arrow (>) for
the __Build__ activity and then click on "Post-actions". Create a new action by clicking on the "+" at the bottom of 
the panel window. Make it look like below:

![Capto_Capture 2022-01-27_05-02-44_PM](https://user-images.githubusercontent.com/686946/151396388-225a8fb0-a47e-4f07-984f-f32843b31835.png)

Be sure to add the script above to a "scripts" directory in your project folder, or just make sure that the path to the 
script is correct for your situation.
