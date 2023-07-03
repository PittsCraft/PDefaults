// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// swiftlint:disable:next missing_docs
let package = Package(
    name: "PDefaults",
    platforms: [
        .macOS(.v12),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PDefaults",
            targets: ["PDefaults"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PDefaults",
            dependencies: []
        ),
        .testTarget(
            name: "PDefaultsTests",
            dependencies: ["PDefaults"]
        )
    ]
)
