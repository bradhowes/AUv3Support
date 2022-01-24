//
//  File.swift
//  
//
//  Created by Brad Howes on 24/01/2022.
//

import UIKit
import os.log

public enum Shared {

  /// The top-level identifier to use for logging
  public static var loggingSubsystem = "SimplyFlange"

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ category: String) -> OSLog { .init(subsystem: loggingSubsystem, category: category) }

  /// Access the storyboard that defines the HostUIView for the AUv3 host app
  public static let hostUIViewStoryboard = Storyboard(name: "HostUIView", bundle: .module)

  /**
   Instantiate a new HostUIView and embed it into the view of the given view controller.

   - parameter parent: the view controller to embed in
   - parameter config: the configuration to use
   - returns: the HostUIViewController of the view that was embedded
   */
  public static func embedHostUIView(into parent: ViewController, config: HostViewConfig) -> HostUIViewController {

    let hostViewController = hostUIViewStoryboard.instantiateInitialViewController() as! HostUIViewController
    hostViewController.setConfig(config)

    parent.view.addSubview(hostViewController.view)
    hostViewController.view.pinToSuperviewEdges()

    parent.addChild(hostViewController)
    parent.view.setNeedsLayout()

    return hostViewController
  }
}
