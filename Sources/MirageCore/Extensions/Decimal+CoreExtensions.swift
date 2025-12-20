//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public extension Decimal {

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
    func percentString(total: Decimal, precision: Int = 0) -> String {
        (self / total).formatted(.percent.precision(.fractionLength(precision)))
    }

    /// Value as percent string like "33%"
    func percentString(precision: Int = 0) -> String {
        formatted(.percent.precision(.fractionLength(precision)))
    }

    /// Value as currency string with two fractional numbers like "$33.00"
    var currencyString: String {
        formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
                .precision(.fractionLength(2))
                .decimalSeparator(strategy: .automatic)
                .grouping(.automatic)
        )
    }

    /// Value as currency string with no fractional numbers like "$33"
    var roundedCurrencyString: String {
        formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
                .precision(.fractionLength(0))
                .rounded(rule: .toNearestOrEven)
                .decimalSeparator(strategy: .automatic)
                .grouping(.automatic)
        )
    }

    /// Value of zero as currency like "$0.00"
    static var zeroCurrencyString: String {
        Decimal.zero.currencyString
    }

    // MARK: - Numeric Conversion

    var intValue: Int {
        NSDecimalNumber(decimal: self).intValue
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
