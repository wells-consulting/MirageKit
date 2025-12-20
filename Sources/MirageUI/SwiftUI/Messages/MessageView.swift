//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct MessageView: View {

    private let message: Message

    public init(_ message: Message) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 0) {
            MessageIcon(message)
                .padding(.vertical, 16)

            if let title = message.title {
                Text(title)
                    .font(.title2)
            }

            Text(message.summary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            if let details = message.details {
                Text(details)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }
}

#endif
