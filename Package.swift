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
            name: "cHitch"
        ),
        .target(
            name: "Hitch",
            dependencies: [ "cHitch" ]),
        .testTarget(
            name: "HitchTests",
            dependencies: ["Hitch"]),
    ]
)
