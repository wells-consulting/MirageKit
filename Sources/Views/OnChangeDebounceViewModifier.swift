//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import Foundation
import SwiftUI

struct DebouncedChangeModifier<Value: Equatable>: ViewModifier {

    let value: Value
    let delay: Double
    let action: (Value) -> Void

    @State private var debounceTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    action(newValue)
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    func mkOnChangeDebounced<Value: Equatable>(
        of value: Value,
        delay: Double = 0.5,
        perform action: @escaping (Value) -> Void,
    ) -> some View {
        modifier(DebouncedChangeModifier(value: value, delay: delay, action: action))
    }
}

#endif // canImport(SwiftUI)
