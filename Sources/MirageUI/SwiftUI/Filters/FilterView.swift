//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FilterView<T>: View {

    // MARK: - Properties

    let filter: Filter<T>
    let onTap: () -> Void

    // MARK: - Body

    public var body: some View {
        content
            .frame(height: 24)
            .overlay {
                Rectangle()
                    .stroke(.secondary, lineWidth: 1.0)
            }
            .foregroundStyle(.primary)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 0) {
            Text(filter.name)
                .padding(.leading)

            Divider()
                .padding(.horizontal, 8)

            Button {
                onTap()
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 10, height: 10)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 8)
        }
    }
}

//// MARK: - Previews
//
// #Preview {
//    FilterView(filter: Filter<Wine>(id: "cabernet", name: "Cabernet", isIncluded: { _ in true }), onTap: {})
// }

#endif
