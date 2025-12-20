//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FormDecimalField: View, FormField {

    // MARK: - Environment

    @Environment(\.isFocused) public var isFocused

    // MARK: - Properties

    public let label: String
    public let caption: Message?
    public let footnote: Message?
    private let formatter: NumberFormatter

    // MARK: - State & Bindings

    @Binding private var value: Decimal

    // MARK: - Initializers

    public init(_ value: Binding<Decimal>, label: String, caption: Message? = nil, format: Format, footnote: Message? = nil) {
        _value = value
        self.label = label
        self.caption = caption
        self.footnote = footnote

        let formatter = NumberFormatter()

        formatter.isLenient = true
        formatter.allowsFloats = true
        formatter.usesGroupingSeparator = true

        switch format {
        case .number:
            formatter.numberStyle = .decimal
        case .currency:
            formatter.numberStyle = .currency
            formatter.minimumIntegerDigits = 1
            formatter.maximumFractionDigits = 2
        }

        self.formatter = formatter
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

            TextField(label, value: $value, formatter: formatter)
                .padding(8)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
                .fieldBorder(style: borderStyle)
        }
    }

    public enum Format {
        case number
        case currency
    }
}

// MARK: - Previews

#Preview {
    VStack {
        FormDecimalField(.constant(Decimal(333.33)), label: "Decimal Number", format: .number)
        FormDecimalField(.constant(Decimal(333.33)), label: "Decimal Currency", format: .currency)
    }
    .padding()
}

#endif
