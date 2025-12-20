//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct MessageLabel: View {

    private let message: Message
    private let textColor: Color

    public init(_ message: Message, textColor: Color = .primary) {
        self.message = message
        self.textColor = textColor
    }

    public var body: some View {
        HStack(alignment: .center) {
            MessageIcon(message)
            Text(message.summary)
                .foregroundStyle(textColor)
        }
    }
}

#endif
