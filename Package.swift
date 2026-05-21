// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SleepEye",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "SleepEye", targets: ["SleepEye"]),
        .library(name: "SleepEyeCore", targets: ["SleepEyeCore"]),
    ],
    targets: [
        .target(name: "SleepEyeCore"),
        .executableTarget(
            name: "SleepEye",
            dependencies: ["SleepEyeCore"]
        ),
        .testTarget(
            name: "SleepEyeCoreTests",
            dependencies: ["SleepEyeCore"]
        ),
    ]
)
