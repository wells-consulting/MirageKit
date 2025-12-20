// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MirageKit",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "MirageCore", targets: ["MirageCore"]),
        .library(name: "MirageUI", targets: ["MirageUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.63.0")
    ],
    targets: [
        .target(
            name: "MirageCore",
            path: "Sources/MirageCore",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("ExistentialAny")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "MirageCoreTests",
            dependencies: ["MirageCore"],
            path: "Tests/MirageCoreTests"
        ),
        .target(
            name: "MirageUI",
            dependencies: ["MirageCore"],
            path: "Sources/MirageUI",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("ExistentialAny")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        )
    ]
)
