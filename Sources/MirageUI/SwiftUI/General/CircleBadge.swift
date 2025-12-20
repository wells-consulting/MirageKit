//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

public struct CircleBadge: View {

    // MARK: - Properties

    let text: String
    let font: Font
    let diameter: Double
    let backgroundColor: Color
    let foregroundColor: Color
    let border: Border

    // MARK: - Initializers

    public init(text: String, diameter: Double, backgroundColor: Color? = nil, foregroundColor: Color? = nil, border: Border = .none) {
        self.diameter = diameter
        self.text = text
        self.backgroundColor = backgroundColor ?? .clear
        self.foregroundColor = foregroundColor ?? .primary
        self.border = border

        self.font = Font.maximumFont(
            fitting: text,
            within: .circle(diameter: diameter),
            startingFont: .boldSystemFont(ofSize: 8.0)
        )
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            switch border {
            case .none:
                EmptyView()

            case let .line(color, width):
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: width))
                    .frame(width: diameter, height: diameter)
                    .foregroundColor(color)
                Circle()
                    .frame(width: diameter - width, height: diameter - width)
                    .foregroundColor(backgroundColor)

            case let .halo(color, width):
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: width))
                    .frame(width: diameter, height: diameter)
                    .foregroundColor(color)
                Circle()
                    .frame(
                        width: diameter - width - 5.0,
                        height: diameter - width - 5.0
                    )
                    .foregroundColor(backgroundColor)
            }

            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
                .padding(4)
        }
    }

    // MARK: - Types

    public enum Border {
        case none
        case line(color: Color, width: Double)
        case halo(color: Color, width: Double)
    }

}

// MARK: - Previews

#Preview {
    CircleBadge(
        text: 1000.formatted(),
        diameter: 300,
        backgroundColor: Color.red,
        foregroundColor: Color.white,
        border: .halo(color: Color.primary, width: 2.0)
    )
}

#endif
