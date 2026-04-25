//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Utility extensions for `String` and `Optional<String>`.
public extension String {

    // MARK: - Properties

    /// `true` if the string is empty or contains only whitespace and newlines.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns `nil` if the string is blank, otherwise returns `self`
    var nilIfBlank: String? {
        isBlank ? nil : self
    }

    // MARK: - Truncation

    /// Where to cut characters when a string exceeds the maximum length.
    enum TruncationPosition { case leading, middle, trailing }

    /// Returns the string truncated to `length` characters, inserting `"…"` at
    /// the specified position if truncation occurs.
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

    /// Removes whitespace and newlines from both ends
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes whitespace and newlines from beginning of string
    func trimmedStart() -> String {
        String(trimmingPrefix(while: { $0.isWhitespace || $0.isNewline }))
    }

    /// Removes whitespace and newlines from end of string
    func trimmedEnd() -> String {
        guard let lastNonWhitespace = lastIndex(
            where: { !$0.isWhitespace && !$0.isNewline },
        ) else {
            return ""
        }
        return String(self[...lastNonWhitespace])
    }

    /// Removes repeating instances of a string from end of a string
    func trimmingSuffix(_ string: String) -> String {
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

    // MARK: - Comparisons

    /// Returns `true` if `lhs` and `rhs` compare as equal under locale-aware rules.
    static func isOrderedSame(
        _ lhs: String,
        _ rhs: String,
        caseSensitive: Bool = false,
    ) -> Bool {
        if caseSensitive {
            lhs.localizedCompare(rhs) == .orderedSame
        } else {
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedSame
        }
    }

    /// Returns `true` if `lhs` sorts after `rhs` under locale-aware rules.
    static func isOrderedDescending(
        _ lhs: String,
        _ rhs: String,
        caseSensitive: Bool = false,
    ) -> Bool {
        if caseSensitive {
            lhs.localizedCompare(rhs) == .orderedDescending
        } else {
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedDescending
        }
    }

    /// Returns `true` if `lhs` sorts before `rhs` under locale-aware rules.
    static func isOrderedAscending(
        _ lhs: String,
        _ rhs: String,
        caseSensitive: Bool = false,
    ) -> Bool {
        if caseSensitive {
            lhs.localizedCompare(rhs) == .orderedAscending
        } else {
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }
}

// MARK: - Optional String

public extension String? {

    /// Returns `true` if the string is `nil` or blank (whitespace only)
    var isBlank: Bool {
        self?.isBlank ?? true
    }
}

// MARK: - Collection

public extension Collection {

    /// `true` if the collection contains at least one element. The inverse of `isEmpty`.
    var isNotEmpty: Bool { !isEmpty }
}

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.isLenient = true
    formatter.numberStyle = .decimal
    formatter.allowsFloats = true
    formatter.usesGroupingSeparator = true
    return formatter
}()
