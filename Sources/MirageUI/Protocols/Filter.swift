//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct Filter<T>: Identifiable, Equatable {

    public let id: String
    public let name: String
    public let visibility: Visibility
    public let isIncluded: (T) -> Bool

    public init(
        id: String,
        name: String? = nil,
        visibility: Visibility = .visible,
        isIncluded: @escaping (T) -> Bool
    ) {
        self.id = id
        self.name = name ?? id
        self.visibility = visibility
        self.isIncluded = isIncluded
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public enum Visibility {
        case visible
        case hidden
    }
}
