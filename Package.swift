// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkLayerSPM",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "NetworkLayerSPM",
            targets: ["NetworkLayerSPM"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "NetworkLayerSPM",
            dependencies: []),
        .testTarget(
            name: "NetworkLayerSPMTests",
            dependencies: ["NetworkLayerSPM"]),
    ]
)
