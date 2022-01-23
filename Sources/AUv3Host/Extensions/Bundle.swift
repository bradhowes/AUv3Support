// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import AVFAudio

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
