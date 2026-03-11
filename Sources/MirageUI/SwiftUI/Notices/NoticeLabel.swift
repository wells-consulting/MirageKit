//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

    import MirageCore
    import SwiftUI

    public struct NoticeLabel: View {

        private let notice: Notice
        private let textColor: Color

        public init(_ notice: Notice, textColor: Color = .primary) {
            self.notice = notice
            self.textColor = textColor
        }

        public var body: some View {
            HStack(alignment: .center) {
                NoticeIcon(notice)
                Text(notice.summary)
                    .foregroundStyle(textColor)
            }
        }
    }

#endif
