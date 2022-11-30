// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Hitch",
    products: [
        .library(name: "Hitch", type: .dynamic, targets: ["Hitch"]),
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
