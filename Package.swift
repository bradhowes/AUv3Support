// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "AUv3SupportPackage",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "AUv3-Support", targets: ["AUv3Support"]),
    .library(name: "AUv3-Support-iOS", targets: ["AUv3Support_iOS"]),
    .library(name: "AUv3-Support-macOS", targets: ["AUv3Support_macOS"]),
    .library(name: "AUv3-DSP-Headers", targets: ["DSPHeaders"]),
  ],
  targets: [
    .target(
      name: "DSPHeaders",
      exclude: ["README.md"],
      cxxSettings: [
        .unsafeFlags([
          "-pedantic",
          "-Wmissing-braces",
          "-Wparentheses",
          "-Wswitch",
          "-Wcompletion-handler",
          "-Wunused-function",
          "-Wunused-label",
          "-Wunused-parameter",
          "-Wunused-variable",
          "-Wunused-value",
          "-Wempty-body",
          "-Wno-unknown-pragmas",
          "-Wuninitialized",
          "-Wconditional-uninitialized",
          "-Wconversion",
          "-Wconstant-conversion",
          "-Wassign-enum",
          "-Wsign-compare",
          "-Wint-conversion",
          "-Wbool-conversion",
          "-Wenum-conversion",
          "-Wfloat-conversion",
          "-Wshorten-64-to-32",
          "-Wsign-conversion",
          "-Wmove",
          "-Wcomma",
          "-Wno-newline-eof", // resource_bundle_accessor.h is missing newline at end of file
          "-x", "objective-c++", // treat source files as Obj-C++ files
        ], .none)
      ]
    ),
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
      dependencies: ["AUv3Support"],
      resources: [.copy("Resources")]
    ),
    .testTarget(
      name: "DSPHeadersTests",
      dependencies: ["DSPHeaders"],
      exclude: ["Pirkle/README.md",
                "Pirkle/readme.txt"],
      linkerSettings: [
        .linkedFramework("AVFoundation")
      ]
    )
  ],
  cxxLanguageStandard: .cxx17
)
