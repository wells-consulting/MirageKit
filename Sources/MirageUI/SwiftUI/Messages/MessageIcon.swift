//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct MessageIcon: View {

    private let message: Message

    public init(_ message: Message) {
        self.message = message
    }

    public var body: some View {
        switch message.severity {
        case .info:
            Image(systemName: "info.circle")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.secondary).opacity(0.8)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.yellow).opacity(0.8)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.red).opacity(0.8)
        }
    }
}

#endif
