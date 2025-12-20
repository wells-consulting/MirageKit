//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

public struct HighlightText: View {

    // MARK: - Properties

    private let text: String
    private let searchText: String
    private let highlightColor: Color

    // MARK: - Computed Properties

    private var attributedString: AttributedString {
        do {
            return try text.highlight(searchText, color: highlightColor)
        } catch {
            // logger.error("\(error)")
            return AttributedString(text)
        }
    }

    // MARK: - Initializers

    public init(_ text: String, searchText: String, highlightColor: Color) {
        self.text = text
        self.searchText = searchText
        self.highlightColor = highlightColor
    }

    // MARK: - Body

    public var body: some View {
        if text.isAllWhitespace {
            Text(text)
        } else {
            Text(attributedString)
        }
    }
}

#endif
