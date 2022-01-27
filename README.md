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

# Usage Notes

The packages here build just fine, but there are issues that crop up when the packages become dependencies in another project involves an app extension or has 
a framework that depends on one of these packages which is then used as a dependeny itself (not clear on the exact conditions). In my particular case with AUv3 
app extensions, the result is that the common framework that is shared between the app extension and the host app will embed within it a Swift package 
dependency that is also present at the top-level of the host app. Apple rightly flags the duplication (plus some other issues) and refuses to upload the archive
artifacts.

The solution that works _for me_ is to have a Bash script run after the build step that deletes the embedded frameworks. Sounds scary, but it works and Apple 
likes what it sees. More importantly, the apps run just fine on iOS and macOS after this framework culling. Here is the script I use: (`post-build.sh`):

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

To use, edit the Xcode scheme that builds your application (iOS or macOS). Click on the disclosure arrow (>) for the __Build__ activity and then click on "Post-actions". Create a new action by clicking on the "+" at the bottom of the panel window. Make it look like below:

<img width="687" alt="Capto_Annotation" src="https://user-images.githubusercontent.com/686946/151394467-d5285482-c690-478a-ae19-8ea669496782.png">

Be sure to add the script above to a "scripts" directory in your project folder, and make sure that it is executable.
