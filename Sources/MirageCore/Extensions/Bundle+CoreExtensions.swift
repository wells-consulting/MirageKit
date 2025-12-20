//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Core Bundle Extensions
public extension Bundle {

    /// App Name
    static let appName: String? = Bundle.main
        .infoDictionary?["CFBundleExecutable"] as? String

    /// App Identifier, i.e., consulting.wells.Mirage
    static let appBundleIdentifier: String? = Bundle.main.bundleIdentifier

    /// App Short Version Number, i.e., 1.0
    static let appShortVersionNumber: String? = Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String

    /// App Build Number
    static let appBuildNumber: String? = Bundle.main
        .infoDictionary?["CFBundleVersion"] as? String

    /// App Version Number Including Build, i.e., 1.0.5
    static var appLongVersionNumber: String? {
        if let appShortVersionNumber, let appBuildNumber {
            "\(appShortVersionNumber) (Build \(appBuildNumber))"
        } else {
            nil
        }
    }

    /// Filename for the App's icon
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
