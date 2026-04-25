//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

/// A secure text field with a toggle button to reveal or hide the value.
public struct RevealableSecureField: View {

    // MARK: - Fields

    private let label: String
    @Binding private var text: String

    // MARK: - State

    @State private var isRevealed = false

    // MARK: - Initializer

    public init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    // MARK: - Body

    public var body: some View {
        #if os(tvOS)
        HStack(alignment: .center, spacing: 20) {
            textField
            Button {
                isRevealed.toggle()
            } label: {
                Label(
                    isRevealed ? "Hide" : "Show",
                    systemImage: isRevealed ? "eye.slash" : "eye",
                )
            }
            .frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        #else
        textField
            .overlay(alignment: .trailing) {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
            }
        #endif
    }

    // MARK: - Subviews

    @ViewBuilder
    private var textField: some View {
        if isRevealed {
            #if os(iOS)
            TextField(label, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            #else
            TextField(label, text: $text)
                .autocorrectionDisabled()
            #endif
        } else {
            SecureField(label, text: $text)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var password = "ItsASecret!"
    VStack {
        RevealableSecureField("Password", text: $password)
    }
    .frame(width: 800)
    .padding(50)
    .background(.white.opacity(0.25))
}
#endif

#endif // canImport(SwiftUI)
