//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public protocol Selectable: Identifiable, Hashable {
    var name: String { get }
}
