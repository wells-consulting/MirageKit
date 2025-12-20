//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI) && !os(tvOS) && !os(watchOS)

import MirageCore
import SwiftUI

public struct FormTextField: View, FormField {

    // MARK: - Environment

    @Environment(\.isFocused) public var isFocused

    // MARK: - Properties

    public let label: String
    public let caption: Message?
    private let style: Style
    public let footnote: Message?

    // MARK: - State & Bindings

    @Binding private var text: String

    // MARK: - Initializers

    public init(_ text: Binding<String>, label: String, caption: Message? = nil, style: Style, hint: String? = nil, footnote: Message? = nil) {
        _text = text
        self.label = label
        self.caption = caption
        self.style = style
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

            Group {
                switch style {
                case .field:
                    TextField("", text: $text)
                case let .editor(height):
                    TextEditor(text: $text)
                        .frame(height: height ?? 100.0)
                        .scrollContentBackground(.hidden)
#if os(iOS)
                        .keyboardType(.alphabet)
#endif
                }
            }
            .padding(8)
            .fieldBorder(style: borderStyle)
#if os(iOS)
                .keyboardType(.alphabet)
#endif
        }
    }

    // MARK: - Types

    public enum Style {
        case field
        case editor(height: Double?)
    }
}

// MARK: - Previews

#Preview {
    VStack {
        FormTextField(.constant("This is a field"), label: "Field", style: .field)
        FormTextField(.constant("This is an editor"), label: "Editor", style: .editor(height: nil))
    }
    .padding()
}

#endif
