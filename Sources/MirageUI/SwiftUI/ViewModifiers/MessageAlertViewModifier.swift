//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

private struct MessageAlertViewModifier: ViewModifier {

    @Binding var message: Message?

    func body(content: Content) -> some View {
        content
            .alert(
                message?.title ?? "Alert",
                isPresented: .constant(message != nil)
            ) {
                Button("OK") {
                    message = nil
                }
            } message: {
                Text(message?.summary ?? "No text was supplied.")
            }
    }
}

public extension View {
    func messageAlert(_ message: Binding<Message?>) -> some View {
        modifier(MessageAlertViewModifier(message: message))
    }
}

#endif
