//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

public extension Color {

    init?(hexString: String) {
        let sanatizedHexString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard sanatizedHexString.count == 6 else {
            return nil
        }

        var rgb: UInt64 = 0

        unsafe Scanner(string: sanatizedHexString).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / CGFloat(255.0)
        let g = CGFloat((rgb & 0x00FF00) >> 8) / CGFloat(255.0)
        let b = CGFloat(rgb & 0x0000FF) / CGFloat(255.0)

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    func hexString() throws -> String? {
        guard let components = PlatformColor(self).cgColor.components else {
            return nil
        }

        guard components.count >= 3 else {
            return nil
        }

        let r = lround(Double(components[0]) * 255)
        let g = lround(Double(components[1]) * 255)
        let b = lround(Double(components[2]) * 255)

        return unsafe String(format: "%02lX%02lX%02lX", r, g, b)
    }
}

#endif
