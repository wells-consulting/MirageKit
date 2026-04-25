//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Convenience extensions for reading common `Info.plist` values from the main bundle.
public extension Bundle {

    /// The executable name declared in `CFBundleExecutable` (e.g. `"MyApp"`).
    static let appName: String = (Bundle.main
        .infoDictionary?["CFBundleExecutable"] as? String) ?? "MirageKit"

    /// The bundle identifier declared in `CFBundleIdentifier` (e.g. `"com.example.MyApp"`).
    static let appBundleIdentifier: String = Bundle.main
        .bundleIdentifier ?? "consulting.wells.MirageKit"

    /// The marketing version declared in `CFBundleShortVersionString` (e.g. `"1.0"`).
    static let appShortVersionNumber: String = (Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String) ?? "-1.0"

    /// The build number declared in `CFBundleVersion` (e.g. `"42"`).
    static let appBuildNumber: String = (Bundle.main
        .infoDictionary?["CFBundleVersion"] as? String) ?? "-1"

    /// The marketing version combined with the build number (e.g. `"1.0 (Build 42)"`).
    /// Returns `"0.0.0"` when either component is unavailable.
    static var appLongVersionNumber: String {
        "\(appShortVersionNumber) (Build \(appBuildNumber))"
    }

    /// The filename of the app's primary icon, sourced from `CFBundleIcons`. Returns `nil`
    /// when no icon is configured or the `Info.plist` keys are absent.
    static var appIconFilename: String? {
        guard
            let icons = Bundle.main
                .object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                let filename = iconFiles.last
        else {
            return nil
        }

        return filename
    }
}
