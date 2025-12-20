//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FormDateField: View, FormField {

    // MARK: - Environment

    @Environment(\.isFocused) public var isFocused

    // MARK: - Properties

    public let label: String
    public let caption: Message?
    public let footnote: Message?

    @Binding private var date: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - State & Bindings

    // MARK: - Initializers

    public init(_ date: Binding<Date>, label: String, caption: Message? = nil, footnote: Message? = nil) {
        _date = date
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
                    MessageLabel(caption)
                        .font(.caption)
                        .truncationMode(.middle)
                }
            }

            TextField(label, value: $date, formatter: dateFormatter)
                .padding(8)
                .fieldBorder(style: borderStyle)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
    }

}

// MARK: - Previews

#Preview {
    VStack {
        FormDateField(.constant(Date.now), label: "Date")
    }
    .padding()
}

#endif
