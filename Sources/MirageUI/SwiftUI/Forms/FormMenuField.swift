//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FormMenuField<T: Selectable>: View, FormField {

    // MARK: - Environment

    @Environment(\.isFocused) public var isFocused

    // MARK: - Properties

    public let label: String
    public let caption: Message?
    public let footnote: Message?
    private let elements: [T]

    // MARK: - State / Bindings

    @Binding var selection: T?

    // MARK: - Initializers

    public init(
        elements: [T],
        label: String,
        selection: Binding<T?>,
        caption: Message? = nil,
        footnote: Message? = nil
    ) {
        self.elements = elements
        self.label = label
        self._selection = selection
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
                    MessageLabel(caption)
                        .font(.caption)
                        .truncationMode(.middle)
                }
            }
            Picker("", selection: $selection) {
                Text("None").tag(nil as T?)
                Divider()
                ForEach(elements) { element in
                    Text(element.name).tag(element as T?)
                }
            }
        }
    }
}

#endif
