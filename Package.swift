// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AUv3Support",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "AUv3Support",
      // Generate static version in order to be used by app extension
      type: .static,
      targets: ["AUv3Support"])
  ],
  dependencies: [
    .package(name: "Knob", url: "https://github.com/bradhowes/Knob", .upToNextMajor(from: .init(1, 0, 0)))
  ],
  targets: [
    .target(
      name: "AUv3Support",
      dependencies: [

        // Depend on the static version in order to be used by app extension
        .productItem(name: "KnobStatic", package: "Knob", condition: nil)
      ],
      exclude: [
        "README.md",
        "User Interface/README.md"
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"],
      resources: [
        .copy("Resources")
      ]
    ),
    .testTarget(
      name: "KernelSupportTests",
      dependencies: ["AUv3Support"],
      cxxSettings: [
        .unsafeFlags(["-std=c++17"])
      ]),
  ]
)
