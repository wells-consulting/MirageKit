//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FormIntField: View, FormField {

    // MARK: - Environment

    @Environment(\.isFocused) public var isFocused

    // MARK: - Properties

    public let label: String
    public let caption: Message?
    public let footnote: Message?

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    // MARK: - State / Binding

    @Binding private var value: Int

    // MARK: - Initializers

    public init(_ value: Binding<Int>, label: String, caption: Message? = nil, footnote: Message? = nil) {
        _value = value
        self.label = label
        self.caption = caption
        self.footnote = footnote
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(.headline)
                if let caption {
                    Spacer()
                    Text(caption.summary)
                        .font(.caption)
                        .truncationMode(.middle)
                }
            }

            TextField(label, value: $value, formatter: formatter)
                .padding(8)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
                .fieldBorder(style: borderStyle)
        }
    }

}

// MARK: - Previews

#Preview {
    VStack {
        FormIntField(.constant(333), label: "Int")
    }
    .padding()
}

#endif
