// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "rectangle_detector",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "rectangle_detector",
            targets: ["rectangle_detector"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "rectangle_detector",
            dependencies: [],
            path: "../Classes",
            sources: [
                "RectangleDetector.swift",
                "RectangleDetectorPlugin.swift",
                "RectangleFeature.swift"
            ],
            publicHeadersPath: "."
        )
    ]
)