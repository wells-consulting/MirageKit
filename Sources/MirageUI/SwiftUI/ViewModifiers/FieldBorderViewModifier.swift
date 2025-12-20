//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

private struct FieldBorderViewModifier: ViewModifier {

    let style: FieldBorderStyle

    private var color: Color {
        switch style {
        case .normal:
            .secondary
        case .focused:
            .primary
        case let .custom(color):
            color
        }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color, lineWidth: 1.0)
            }
    }

}

public extension View {
    func fieldBorder(style: FieldBorderStyle = .normal) -> some View {
        modifier(FieldBorderViewModifier(style: style))
    }
}

public enum FieldBorderStyle {
    case normal
    case focused
    case custom(Color)
}

#Preview {
    VStack {
        TextField("Normal", text: .constant("Normal"))
            .padding(8)
            .fieldBorder(style: .normal)
            .padding()
        TextField("Focused", text: .constant("Focused"))
            .padding(8)
            .fieldBorder(style: .focused)
            .padding()
        TextField("Warn", text: .constant("Warn"))
            .padding(8)
            .fieldBorder(style: .custom(.orange))
            .padding()
        TextField("Error", text: .constant("Error"))
            .padding(8)
            .fieldBorder(style: .custom(.red))
            .padding()
    }
}

#endif
