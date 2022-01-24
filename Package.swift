// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AUv3SupportPackage",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "AUv3-Support-Static",
      type: .static,
      targets: ["AUv3Support"])
  ],
  targets: [
    .target(
      name: "AUv3Support",
      dependencies: [],
      exclude: [],
      resources: [.process("Resources")],
      swiftSettings: [
        .define("APPLICATION_EXTENSION_API_ONLY=YES")
      ]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: []
    )
  ]
)
