//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Types providing summary text.
///
/// ```swift
///
/// let lotsOfData = try await URLSession.shared.data(for: urlRequest)
///
/// print(lotsOfData.summary)
/// ```
///     25.8 GB
///
public protocol SummaryProviding {
    var summary: String { get }
}
