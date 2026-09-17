// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChinTopCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ChinTopCore", targets: ["ChinTopCore"])
    ],
    targets: [
        .target(
            name: "ChinTopCore",
            path: "ChinTopApp/Core"
        ),
        .testTarget(
            name: "ChinTopCoreTests",
            dependencies: ["ChinTopCore"],
            path: "Tests"
        )
    ]
)
