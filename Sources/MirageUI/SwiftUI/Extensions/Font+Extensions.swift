//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

public extension Font {

    enum FitShape {
        case rectangle(width: Double, height: Double)
        case circle(diameter: Double)
    }

    // For now, we compute this on the fly with no caching. It
    // uses a binary search so it should be fast enough for
    // general use, but the results could be cached later if
    // it becomes necessary.

    static func maximumFont(fitting text: String, within shape: FitShape, startingFont font: PlatformFont, minPointSize: Double = 4.0, maxPointSize: Double = 128.0) -> Font {
        var constrainedSize: CGSize

        switch shape {
        case let .rectangle(width: width, height: height):
            constrainedSize = CGSize(width: width, height: height)
        case let .circle(diameter: diameter):
            let length = sqrt(2.0) * (diameter / 2.0)
            constrainedSize = CGSize(width: length, height: length)
        }

        var minPointSize = minPointSize
        var maxPointSize = maxPointSize
        var midPointSize = minPointSize

        var fittedSize = constrainedSize

        while maxPointSize - minPointSize > 1.0 {
            midPointSize = ((minPointSize + maxPointSize) / 2.0)

            fittedSize = text.size(withAttributes: [.font: font.withSize(midPointSize)])

            if fittedSize.height <= constrainedSize.height, fittedSize.width <= constrainedSize.width {
                minPointSize = midPointSize
            } else {
                maxPointSize = midPointSize
            }
        }

        return Font(font.withSize(midPointSize))
    }
}

#endif
