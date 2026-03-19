// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MirageKit",
    platforms: [
        .iOS(.v18),
        .watchOS(.v9),
        .tvOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "MirageKit", targets: ["MirageKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.63.0"),
    ],
    targets: [
        .target(
            name: "MirageKit",
            path: "Sources",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ],
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["MirageKit"],
            path: "Tests",
        ),
    ],
)
