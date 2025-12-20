//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

public extension View {

    func debugAction(_ closure: () -> Void) -> Self {
#if DEBUG
        closure()
#endif

        return self
    }

    func debugPrint(_ value: Any) -> Self {
        debugAction { print(value) }
    }
}

#endif
