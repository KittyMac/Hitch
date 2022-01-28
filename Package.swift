// swift-tools-version:5.1.0

import PackageDescription

let package = Package(
    name: "Hitch",
    products: [
        .library(
            name: "Hitch",
            targets: ["Hitch"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "Hitch",
            dependencies: []),
        .testTarget(
            name: "HitchTests",
            dependencies: ["Hitch"]),
    ]
)
