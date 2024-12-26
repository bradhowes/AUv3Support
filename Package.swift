// swift-tools-version:6.0

import PackageDescription
import Foundation

let flags = [
  "-pedantic",
  "-Wall",
  "-Wassign-enum",
  "-Wbad-function-cast",
  "-Wbind-to-temporary-copy",
  "-Wbool-conversion",
  "-Wbool-operation",
  "-Wc++11-extra-semi",
  "-Wcast-align",
  "-Wcast-function-type",
  "-Wcast-qual",
  "-Wchar-subscripts",
  "-Wcomma",
  "-Wcompletion-handler",
  "-Wconditional-uninitialized",
  "-Wconsumed",
  "-Wconversion",
  "-Wcovered-switch-default",
  "-Wdeclaration-after-statement",
  "-Wdeprecated",
  "-Wdeprecated-copy",
  "-Wdeprecated-copy-with-user-provided-dtor",
  "-Wdeprecated-dynamic-exception-spec",
  "-Wdeprecated-implementations",
  "-Wdirect-ivar-access",
  "-Wdocumentation",
  "-Wdocumentation-pedantic",
  // "-Wdouble-promotion",
  "-Wduplicate-decl-specifier",
  "-Wduplicate-enum",
  "-Wduplicate-method-arg",
  "-Wduplicate-method-match",
  "-Weffc++",
  "-Wempty-init-stmt",
  "-Wempty-translation-unit",
  "-Wenum-conversion",
  "-Wexplicit-ownership-type",
  "-Wfloat-conversion",
  "-Wfor-loop-analysis",
  "-Wformat-nonliteral",
  "-Wformat-type-confusion",
  "-Wframe-address",
  // "-Wglobal-constructors",
  "-Wheader-hygiene",
  "-Widiomatic-parentheses",
  "-Wimplicit-fallthrough",
  "-Wimplicit-retain-self",
  "-Wincompatible-function-pointer-types",
  "-Wlogical-op-parentheses",
  "-Wmethod-signatures",
  "-Wmismatched-tags",
  "-Wmissing-braces",
  "-Wmissing-field-initializers",
  "-Wmissing-method-return-type",
  "-Wmissing-noreturn",
  // "-Wmissing-prototypes",
  "-Wmissing-variable-declarations",
  "-Wmove",
  "-Wno-newline-eof", // resource_bundle_accessor.h is missing newline at end of file
  "-Wno-unknown-pragmas",
  "-Wnon-virtual-dtor",
  "-Wnullable-to-nonnull-conversion",
  "-Wobjc-interface-ivars",
  "-Wobjc-missing-property-synthesis",
  "-Wobjc-property-assign-on-object-type",
  "-Wobjc-signed-char-bool-implicit-int-conversion",
  "-Wold-style-cast",
  "-Wover-aligned",
  "-Woverlength-strings",
  "-Woverriding-method-mismatch",
  // "-Wpadded",
  "-Wparentheses",
  "-Wpessimizing-move",
  "-Wpointer-arith",
  "-Wrange-loop-analysis",
  "-Wredundant-move",
  "-Wreorder",
  "-Wself-assign-overloaded",
  "-Wself-move",
  "-Wsemicolon-before-method-body",
  "-Wshadow-all",
  "-Wshorten-64-to-32",
  "-Wsign-compare",
  "-Wsign-conversion",
  "-Wsometimes-uninitialized",
  "-Wstrict-selector-match",
  "-Wstring-concatenation",
  "-Wstring-conversion",
  "-Wsuggest-destructor-override",
  "-Wsuggest-override",
  "-Wsuper-class-method-mismatch",
  // "-Wswitch-enum",
  "-Wundefined-internal-type",
  "-Wundefined-reinterpret-cast",
  "-Wuninitialized",
  "-Wuninitialized-const-reference",
  "-Wunneeded-internal-declaration",
  "-Wunneeded-member-function",
  "-Wunreachable-code-aggressive",
  // "-Wunsafe-buffer-usage",
  "-Wunused",
  "-Wunused-function",
  "-Wunused-label",
  "-Wunused-parameter",
  "-Wunused-private-field",
  "-Wunused-value",
  "-Wunused-variable",
  // "-Wzero-as-null-pointer-constant",
  "-Wzero-length-array",
  "-x", "objective-c++", // treat source files as Obj-C++ files
]

let useUnsafeFlags: Bool = ProcessInfo.processInfo.environment["USE_UNSAFE_FLAGS"] != nil
let cxxSettings: [CXXSetting] = useUnsafeFlags ? [.unsafeFlags(flags, .when(configuration: .debug))] : []

NSLog("--- compiling with UNSAFE C++ flags: %d", useUnsafeFlags)

let package = Package(
  name: "AUv3Support",
  platforms: [.iOS(.v16), .macOS(.v14)],
  products: [
    .library(name: "AUv3-Support", targets: ["AUv3Support"]),
    .library(name: "AUv3-Support-iOS", targets: ["AUv3Support-iOS-only"]),
    .library(name: "AUv3-Support-macOS", targets: ["AUv3Support-macOS-only"]),
    .library(name: "AUv3-DSP-Headers", targets: ["DSPHeaders"]),
  ],
  targets: [
    .target(
      name: "DSPHeaders",
      exclude: ["README.md"],
      cxxSettings: cxxSettings
    ),
    .target(
      name: "AUv3Support",
      dependencies: ["DSPHeaders"],
      exclude: [],
      resources: [.process("Resources")],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .target(
      name: "AUv3Support-iOS-only",
      dependencies: [.targetItem(name: "AUv3Support-iOS", condition: .when(platforms: [.iOS]))]
    ),
    .target(
      name: "AUv3Support-iOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      resources: [.process("Resources")],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .target(
      name: "AUv3Support-macOS-only",
      dependencies: [.targetItem(name: "AUv3Support-macOS", condition: .when(platforms: [.macOS]))]
    ),
    .target(
      name: "AUv3Support-macOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"],
      resources: [.copy("Resources")],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "AUv3Support-iOSTests",
      dependencies: [
        .targetItem(name: "AUv3Support-iOS-only", condition: .when(platforms: [.iOS])),
        "AUv3Support"
      ],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "AUv3Support-macOSTests",
      dependencies: [
        .targetItem(name: "AUv3Support-macOS-only", condition: .when(platforms: [.macOS])),
        "AUv3Support"
      ],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "DSPHeadersTests",
      dependencies: ["DSPHeaders"],
      exclude: ["Pirkle/README.md", "Pirkle/readme.txt"],
      linkerSettings: [.linkedFramework("AVFoundation")]
    ),
    .testTarget(
      name: "AUv3Support-iOS-only-tests",
      dependencies: [
        .targetItem(name: "AUv3Support-iOS", condition: .when(platforms: [.iOS])),
        "AUv3Support"
      ],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "AUv3Support-macOS-only-tests",
      dependencies: [
        .targetItem(name: "AUv3Support-macOS", condition: .when(platforms: [.macOS])),
        "AUv3Support"
      ],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY"), .interoperabilityMode(.Cxx)]
    )
  ],
  cxxLanguageStandard: .cxx2b
)
