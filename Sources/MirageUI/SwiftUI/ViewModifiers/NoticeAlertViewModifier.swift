//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

    import MirageCore
    import SwiftUI

    private struct NoticeAlertViewModifier: ViewModifier {

        @Binding var notice: Notice?

        func body(content: Content) -> some View {
            content
                .alert(
                    notice?.title ?? "Alert",
                    isPresented: .constant(notice != nil),
                ) {
                    Button("OK") {
                        notice = nil
                    }
                } message: {
                    Text(notice?.summary ?? "No text was supplied.")
                }
        }
    }

    public extension View {
        func noticeAlert(_ notice: Binding<Notice?>) -> some View {
            modifier(NoticeAlertViewModifier(notice: notice))
        }
    }

#endif
