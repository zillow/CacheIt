// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CacheIt",
        platforms: [
        .iOS(.v11),
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "CacheIt",
            targets: ["CacheIt"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CacheIt",
            dependencies: []),
    ]
)

