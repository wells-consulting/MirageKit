//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

private struct OnLoadViewModifier: ViewModifier {

    var action: (() -> Void)?

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    action?()
                }
            }
    }
}

public extension View {
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(OnLoadViewModifier(action: action))
    }
}

#endif
