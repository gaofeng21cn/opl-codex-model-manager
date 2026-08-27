// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CodexModelManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexModelManager", targets: ["CodexModelManager"]),
        .executable(name: "CodexModelSync", targets: ["CodexModelSync"])
    ],
    targets: [
        .target(
            name: "CodexModelCore",
            path: "Sources/CodexModelCore"
        ),
        .executableTarget(
            name: "CodexModelManager",
            dependencies: ["CodexModelCore"],
            path: "Sources/CodexModelManager"
        ),
        .executableTarget(
            name: "CodexModelSync",
            dependencies: ["CodexModelCore"],
            path: "Sources/CodexModelSync"
        ),
        .testTarget(
            name: "CodexModelManagerTests",
            dependencies: ["CodexModelManager", "CodexModelCore"],
            path: "Tests/CodexModelManagerTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
