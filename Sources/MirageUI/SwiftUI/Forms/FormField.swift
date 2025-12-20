//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public protocol FormField: View {
    var label: String { get }
    var caption: Message? { get }
    var footnote: Message? { get }
    var isFocused: Bool { get }
    var borderStyle: FieldBorderStyle { get }
}

public extension FormField {
    var borderStyle: FieldBorderStyle {
        if footnote?.severity == .error {
            .custom(.red)
        } else if footnote?.severity == .warning {
            .custom(.orange)
        } else if isFocused {
            .focused
        } else {
            .normal
        }
    }
}

#endif
