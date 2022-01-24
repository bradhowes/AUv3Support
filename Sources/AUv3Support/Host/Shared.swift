//
//  File.swift
//  
//
//  Created by Brad Howes on 24/01/2022.
//

import UIKit

public enum Shared {

  public static let hostUIViewStoryboard = Storyboard(name: "HostUIView", bundle: .module)

  public static func embedHostUIView(into parent: ViewController,
                                     config: HostViewConfig) -> HostUIViewController {

    let hostViewController = hostUIViewStoryboard.instantiateInitialViewController() as! HostUIViewController
    
    hostViewController.setConfig(config)

    parent.view.addSubview(hostViewController.view)
    hostViewController.view.pinToSuperviewEdges()

    parent.addChild(hostViewController)
    parent.view.setNeedsLayout()

    return hostViewController
  }
}
