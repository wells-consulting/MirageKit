//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct FilterBar<T>: View {

    // MARK: - Properties

    let filters: [Filter<T>]
    let onTap: (Filter<T>) -> Void

    // MARK: - Initializers

    public init(filters: [Filter<T>], onTap: @escaping (Filter<T>) -> Void) {
        self.filters = filters
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(filters) { filter in
                    FilterView(filter: filter) {
                        onTap(filter)
                    }
                }
            }
        }
    }
}

//// MARK: - Previews
//
// #Preview {
//    let previewDatastore = PreviewDatastore()
//    FilterBar(
//        filters: previewDatastore.tagList.map { tag in
//            Filter<Wine>(id: "\(tag.id)", isIncluded: { _ in true })
//        },
//        onTap: { _ in }
//    )
//    .padding()
//    .modelContainer(previewDatastore.modelContainer)
// }

#endif
