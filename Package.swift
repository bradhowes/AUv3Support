// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "AUv3SupportPackage",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "AUv3-Support", targets: ["AUv3Support"]),
    .library(name: "AUv3-Support-iOS", targets: ["AUv3Support_iOS"]),
    .library(name: "AUv3-Support-macOS", targets: ["AUv3Support_macOS"])
  ],
  targets: [
    .target(
      name: "AUv3Support",
      dependencies: [],
      exclude: [],
      resources: [.process("Resources")],
      swiftSettings: [
        .define("APPLICATION_EXTENSION_API_ONLY")
      ]
    ),
    .target(
      name: "AUv3Support_iOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      resources: [.process("Resources")],
      swiftSettings: [
        .define("APPLICATION_EXTENSION_API_ONLY")
      ]
    ),
    .target(
      name: "AUv3Support_macOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      swiftSettings: [
        .define("APPLICATION_EXTENSION_API_ONLY")
      ]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"]
    )
  ]
)
