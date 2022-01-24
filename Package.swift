// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AUv3Support",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "AUv3ComponentStatic",
      // Generate static version in order to be used by app extension
      type: .static,
      targets: ["AUv3Component"]),
    .library(
      name: "AUv3Host",
      targets: ["AUv3Host"])
  ],
  targets: [
    .target(
      name: "AUv3Host",
      dependencies: ["AUv3Support"],
      exclude: [],
      resources: [.process("Resources")]
    ),
    .target(
      name: "AUv3Component",
      dependencies: ["AUv3Support"],
      exclude: [
        "README.md",
        "User Interface/README.md"
      ]
    ),
    .target(
      name: "AUv3Support",
      dependencies: [],
      exclude: []
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: []
    ),
    .testTarget(
      name: "KernelSupportTests",
      dependencies: [],
      cxxSettings: [
        .unsafeFlags(["-std=c++17"])
      ]),
  ]
)
