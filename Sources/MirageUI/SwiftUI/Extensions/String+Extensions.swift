//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public extension String {

    func highlight(_ searchText: String?, color: Color = .blue) throws -> AttributedString {
        guard let searchText, !isEmpty, !searchText.isEmpty else {
            return AttributedString(self)
        }

        let regex = try NSRegularExpression(pattern: "\(searchText)", options: [.caseInsensitive])
        return try getAttributedHighlightString(regex: regex, color: color)
    }

    private func getAttributedHighlightString(regex: NSRegularExpression, color: Color) throws -> AttributedString {
        let nsAttributedString = NSMutableAttributedString(string: self)

        let replacementColor = PlatformColor(color)

        for match in regex.matches(in: self, range: NSRange(location: 0, length: count)) {
            for index in 0 ..< match.numberOfRanges {
                let range = match.range(at: index)
                nsAttributedString.setAttributes(
                    [
                        NSMutableAttributedString.Key.foregroundColor: replacementColor
                    ],
                    range: range
                )
            }
        }

#if os(iOS)
        return try AttributedString(nsAttributedString, including: \.uiKit)
#else
        return AttributedString(nsAttributedString)
#endif
    }
}

#endif
