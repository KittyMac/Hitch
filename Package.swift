// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "HitchKit",
    products: [
        .library(
            name: "HitchKit",
            targets: ["HitchKit"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "HitchKit",
            dependencies: []),
        .testTarget(
            name: "HitchTests",
            dependencies: ["HitchKit"]),
    ]
)
