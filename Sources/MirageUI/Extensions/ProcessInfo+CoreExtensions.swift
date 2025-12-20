//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public extension ProcessInfo {

    var isRunningInSwiftUIPreview: Bool {
        let processName = processName.lowercased()
        // Common patterns: "xcode", "previews", "xcodebuild"
        return processName.contains("xcode") || processName.contains("previews")
    }
}
