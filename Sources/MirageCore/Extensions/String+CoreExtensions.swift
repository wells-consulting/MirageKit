//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Core String extensions
public extension String {

    // MARK: - Properties

    var isAllWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Truncation

    enum TruncationPosition { case leading, middle, trailing }

    /// Truncates a string to a specified length
    func truncating(to length: Int, position: TruncationPosition) -> String {
        guard count > length else { return self }

        switch position {
        case .leading:
            return "..." + String(suffix(length))

        case .middle:
            let numPrefixChars = Int(ceil(Double(length) / 2.0))
            let numSuffixChars = Int(floor(Double(length) / 2.0))
            return String(prefix(numPrefixChars)) + " ... " + String(suffix(numSuffixChars))

        case .trailing:
            return String(prefix(length)) + "..."
        }
    }

    // MARK: - Trimming

    /// Removes whitespace and newlines from beginning of string
    func removingLeadingWhitespace() -> String {
        let value = self
        return String(value.trimmingPrefix(while: { $0.isWhitespace || $0.isNewline }))
    }

    /// Removes whitespace and newlines from end of string
    /// Convenience function for String.trimmingCharacters(in: .whitespacesAndNewLines)
    func removingTrailingWhitespace() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes instances of a string from end of a string
    func removingTrailingInstances(of string: String) -> String {
        var value = self
        while value.hasSuffix(string) {
            value = String(value.dropLast(string.count))
        }
        return value
    }

    // MARK: - Numeric Conversion

    /// Best try at converting string to Int
    /// Accounts for grouping separators
    var intValue: Int? {
        if let value = Int(self) {
            value
        } else if let value = try? Int(self, format: .number.grouping(.automatic)) {
            value
        } else if let value = try? Int(self, format: .number.grouping(.never)) {
            value
        } else {
            nil
        }
    }

    /// Best try at converting string to Double
    /// Accounts for grouping separators
    var doubleValue: Double? {
        if let value = Double(self) {
            value
        } else if let value = try? Double(self, format: .number.grouping(.automatic)) {
            value
        } else if let value = try? Double(self, format: .number.grouping(.never)) {
            value
        } else {
            nil
        }
    }

    /// Best try at converting string to Decimal
    /// Accounts for grouping separators
    var decimalValue: Decimal? {
        if let value = decimalFormatter.number(from: self) as? Decimal {
            value
        } else if let value = Double(self) {
            Decimal(value) // This may be lossy (should it be allowed?)
        } else {
            nil
        }
    }
}

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.isLenient = true
    formatter.numberStyle = .decimal
    formatter.allowsFloats = true
    formatter.usesGroupingSeparator = true
    return formatter
}()
