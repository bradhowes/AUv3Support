// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AUv3Support",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "AUv3Support",
      targets: ["AUv3Support"]),
  ],
  dependencies: [
    .package(name: "Knob", url: "https://github.com/bradhowes/Knob", .upToNextMajor(from: .init(1, 0, 0)))
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "AUv3Support",
      dependencies: ["Knob"],
      exclude: [
        "Support/README.md",
        "User Interface/README.md"
      ],
      resources: [
        .copy("Support/Audio/074_acoustic-guitar-strummy2.wav"),
        .copy("Support/Audio/Sweet Strummer 02.caf")
      ]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"]),
  ]
)
