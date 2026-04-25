//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import Foundation
import SwiftUI

/// A horizontal progress bar that fills proportionally to `progress` (0.0–1.0).
public struct ProgressBar: View {

    public let progress: Double
    public let colors: [Color]

    public init(progress: Double, colors: [Color]) {
        self.progress = progress
        self.colors = colors
    }

    public var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width - 20
            let fillWidth = max(25, trackWidth * progress)
            Capsule()
                .fill(Color.black.opacity(0.4))
                .frame(width: trackWidth, height: 14)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing,
                        ))
                        .frame(width: fillWidth, height: 10)
                        .padding(.horizontal, 3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(max(0, min(1, progress)) * 100))%")
    }
}

#endif // canImport(SwiftUI)
