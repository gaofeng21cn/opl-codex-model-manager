// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CodexModelManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexModelManager", targets: ["CodexModelManager"])
    ],
    targets: [
        .executableTarget(
            name: "CodexModelManager",
            path: "Sources/CodexModelManager"
        ),
        .testTarget(
            name: "CodexModelManagerTests",
            dependencies: ["CodexModelManager"],
            path: "Tests/CodexModelManagerTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
