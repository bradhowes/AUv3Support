//
//  File.swift
//  
//
//  Created by Brad Howes on 26/01/2022.
//

import Foundation

public struct HostViewConfig {
  public let name: String
  public let version: String
  public let appStoreId: String
  public let componentDescription: AudioComponentDescription
  public let sampleLoop: AudioUnitLoader.SampleLoop
  public let appStoreVisitor: (URL) -> Void

  public init(name: String, version: String, appStoreId: String, componentDescription: AudioComponentDescription,
              sampleLoop: AudioUnitLoader.SampleLoop, appStoreVisitor: @escaping (URL) -> Void) {
    self.name = name
    self.version = version
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.appStoreVisitor = appStoreVisitor
  }
}
