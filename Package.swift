// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "AUv3SupportPackage",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "AUv3-Support", targets: ["AUv3Support"]),
    .library(name: "AUv3-Support-iOS", targets: ["AUv3Support-iOS"]),
    .library(name: "AUv3-Support-macOS", targets: ["AUv3Support-macOS"]),
    .library(name: "AUv3-DSP-Headers", targets: ["DSPHeaders"]),
  ],
  targets: [
    .target(
      name: "DSPHeaders",
      exclude: ["README.md"],
      cxxSettings: [
        .unsafeFlags([
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
        ], .none)
      ]
    ),
    .target(
      name: "AUv3Support",
      dependencies: [],
      exclude: [],
      resources: [.process("Resources")],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY")]
    ),
    .target(
      name: "AUv3Support-iOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      resources: [.process("Resources")],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY")]
    ),
    .target(
      name: "AUv3Support-macOS",
      dependencies: ["AUv3Support"],
      exclude: ["README.md"],
      swiftSettings: [.define("APPLICATION_EXTENSION_API_ONLY")]
    ),
    .testTarget(
      name: "AUv3SupportTests",
      dependencies: ["AUv3Support"],
      resources: [.copy("Resources")]
    ),
    .testTarget(
      name: "AUv3Support-iOSTests",
      dependencies: ["AUv3Support", "AUv3Support-iOS"]
    ),
    .testTarget(
      name: "AUv3Support-macOSTests",
      dependencies: ["AUv3Support", "AUv3Support-macOS"]
    ),
    .testTarget(
      name: "DSPHeadersTests",
      dependencies: ["DSPHeaders"],
      exclude: ["Pirkle/README.md", "Pirkle/readme.txt"],
      linkerSettings: [.linkedFramework("AVFoundation")]
    )
  ],
  cxxLanguageStandard: .cxx17
)
