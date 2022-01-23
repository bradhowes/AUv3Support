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
      targets: ["AUv3Support"]),
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
      name: "AUv3Support",
      dependencies: [],
      exclude: [
        "README.md",
        "User Interface/README.md"
      ]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"]
    ),
    .testTarget(
      name: "KernelSupportTests",
      dependencies: ["AUv3Support"],
      cxxSettings: [
        .unsafeFlags(["-std=c++17"])
      ]),
  ]
)
