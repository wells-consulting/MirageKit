//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Formatting helpers
public extension Double {

    // MARK: - String Conversion

    func string(precision: Int = 1, grouping: NumberFormatStyleConfiguration.Grouping = .automatic) -> String {
        formatted(
            .number
                .precision(.fractionLength(precision))
                .decimalSeparator(strategy: .always)
                .grouping(grouping)
        )
    }

    /// Value as percent string calculated using a maximum value
    func percentString(total: Double, precision: Int = 0) -> String {
        (self / total).formatted(.percent.precision(.fractionLength(precision)))
    }

    /// Value as percent string like "33%"
    func percentString(precision: Int = 0) -> String {
        formatted(.percent.precision(.fractionLength(precision)))
    }

    /// Value as currency string like "$33.00"
    func currencyString(precision: Int = 2, grouping: NumberFormatStyleConfiguration.Grouping = .automatic) -> String {
        formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
                .precision(.fractionLength(precision))
                .decimalSeparator(strategy: .always)
                .grouping(grouping)
        )
    }
}
