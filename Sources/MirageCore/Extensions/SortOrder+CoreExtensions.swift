//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public extension SortOrder {

    mutating func toggle() {
        switch self {
        case .forward:
            self = .reverse
        case .reverse:
            self = .forward
        }
    }
}
