// swift-tools-version:5.0
// Package.swift for VSCode Swift plugin support
// This file helps VSCode understand the project structure

import PackageDescription

let package = Package(
    name: "RectangleDetectorPlugin",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "RectangleDetectorPlugin",
            targets: ["RectangleDetectorPlugin"]
        )
    ],
    dependencies: [
        // No external dependencies for this plugin
    ],
    targets: [
        .target(
            name: "RectangleDetectorPlugin",
            path: "ios/Classes",
            sources: [
                "RectangleDetector.swift",
                "RectangleDetectorPlugin.swift"
            ],
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreImage")
            ]
        )
    ]
)