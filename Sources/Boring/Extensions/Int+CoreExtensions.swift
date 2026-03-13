//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public extension Int {

    // MARK: - String Conversion

    func string(
        grouping: NumberFormatStyleConfiguration.Grouping = .automatic,
    ) -> String {
        formatted(.number.grouping(grouping))
    }
}
