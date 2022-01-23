// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import AVFAudio

private extension Bundle {

  /**
   Attempt to get a String value from the Bundle meta dictionary.

   - parameter key: what to fetch
   - returns: the value found or an empty string
   */
  func info(for key: String) -> String { infoDictionary?[key] as? String ?? "" }
}

public extension Bundle {
  
  /// Obtain the bundle identifier or "" if there is not one
  static var bundleID: String { Bundle.main.bundleIdentifier?.lowercased() ?? "" }

  /// Obtain the build scheme that was used to generate the bundle. Returns " Dev" or " Staging" or ""
  static var scheme: String {
    if bundleID.contains(".dev") { return " Dev" }
    if bundleID.contains(".staging") { return " Staging" }
    return ""
  }
}

public extension Bundle {

  /// Obtain the release version number associated with the bundle or "" if none found
  var releaseVersionNumber: String { info(for: "CFBundleShortVersionString") }

  /// Obtain the build version number associated with the bundle or "" if none found
  var buildVersionNumber: String { info(for: "CFBundleVersion") }

  /// Obtain a version string with the following format: "Version V.B[ S]"
  /// where V is the releaseVersionNumber, B is the buildVersionNumber and S is the scheme.
  var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(Self.scheme)" }

  // NOTE: for the following values to have meaningful values, one must define them in an Info.plist file for the
  // bundle where this file resides.

  /// Obtain the base name of the audio unit
  var auBaseName: String { info(for: "AU_BASE_NAME") }
  /// Obtain the component name of the audio unit
  var auComponentName: String { info(for: "AU_COMPONENT_NAME") }
  /// Obtain the type of the audio unit as a string
  var auComponentTypeString: String { info(for: "AU_COMPONENT_TYPE") }
  /// Obtain the subtype of the audio unit as a string
  var auComponentSubtypeString: String { info(for: "AU_COMPONENT_SUBTYPE") }
  /// Obtain the manufacturer of the audio unit as a string
  var auComponentManufacturerString: String { info(for: "AU_COMPONENT_MANUFACTURER") }
  /// Obtain the type of the audio unit
  var auComponentType: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_TYPE")) }
  /// Obtain the subtype of the audio unit
  var auComponentSubtype: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_SUBTYPE")) }
  /// Obtain the manufacturer of the audio unit
  var auComponentManufacturer: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_MANUFACTURER")) }
  /// Obtain the extension name
  var auExtensionName: String { auBaseName + "AU.appex" }
  /// Obtain the extension URL
  var auExtensionUrl: URL? { builtInPlugInsURL?.appendingPathComponent(auExtensionName) }
  /// Obtain the Apple Store ID for the component
  var appStoreId: String { info(for: "APP_STORE_ID") }
}

public extension Bundle {

  static func audioFileResource(name: String) -> AVAudioFile {
    let parts = name.split(separator: .init("."))
    let filename = String(parts[0])
    let ext = String(parts[1])

    let bundles = Bundle.allBundles + [Bundle.module]
    for bundle in bundles {
      if let url = bundle.url(forResource: filename, withExtension: ext) {
        return try! AVAudioFile(forReading: url)
      }
    }

    fatalError("\(filename).\(ext) missing from bundle")
  }
}
