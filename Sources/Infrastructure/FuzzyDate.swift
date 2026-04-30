//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// A fully-typed representation of a fuzzy calendar date string.
///
/// Parses strings like "2024-08-20", "2024-08", or "2024" and stores the
/// resulting `Date`, `Precision`, and original `rawValue` together. Callers
/// get precision and display methods directly — no string length inspection
/// or static utility calls required.
///
/// Partial dates default to the earliest representable instant: year-only
/// becomes January 1, year-month becomes the 1st of that month.
public struct FuzzyDate: Sendable, Hashable, Comparable, Codable {

    // MARK: - Precision

    public enum Precision: Int, Sendable, Hashable, Comparable {
        case yearOnly = 0
        case yearMonth = 1
        case full = 2

        public static func < (lhs: Precision, rhs: Precision) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Stored Properties

    /// The trimmed original wire string used to construct this value.
    public let rawValue: String
    /// The parsed date. Partial dates default to the earliest instant (Jan 1 for year-only, 1st of month for year-month).
    public let date: Date
    /// The precision of the original string.
    public let precision: Precision

    // MARK: - Initialization

    /// Creates a `FuzzyDate` from a fuzzy date string, or returns `nil` if unparseable.
    ///
    /// Supported formats (tried in order):
    /// 1. ISO 8601 with time ("2024-06-15T00:00:00Z")
    /// 2. "yyyy-MM-dd" or "yyyy/MM/dd"
    /// 3. "yyyy-MM" or "yyyy/MM"
    /// 4. "yyyy" (four-digit year only)
    /// 5. "MM-dd-yyyy" or "MM/dd/yyyy" (US) / "dd-MM-yyyy" (EU)
    ///
    /// For US/EU ambiguity (both components ≤ 12), US format is assumed.
    public init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let result = Self.parseWithPrecision(trimmed) else { return nil }
        rawValue = trimmed
        date = result.date
        precision = result.precision
    }

    // MARK: - Codable

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = FuzzyDate(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse '\(string)' as FuzzyDate"
            )
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    // MARK: - Comparable

    public static func < (lhs: FuzzyDate, rhs: FuzzyDate) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.precision < rhs.precision
    }

    // MARK: - Display

    /// Formats the date for human display, preserving the precision of the original string.
    ///
    /// - "2024-06-15" → "June 15, 2024"
    /// - "2024-06"    → "June 2024"
    /// - "2024"       → "2024"
    public var displayString: String {
        switch precision {
        case .full: return date.formatted(Self.fullDateStyle)
        case .yearMonth: return date.formatted(Self.monthYearStyle)
        case .yearOnly: return date.formatted(Self.yearOnlyStyle)
        }
    }

    /// Formats the date as "Month YYYY" (e.g., "June 2024"), or year-only if precision is `.yearOnly`.
    ///
    /// - "2024-06-15" → "June 2024"
    /// - "2024-06"    → "June 2024"
    /// - "2024"       → "2024"
    public var monthYearString: String {
        switch precision {
        case .full, .yearMonth: return date.formatted(Self.monthYearStyle)
        case .yearOnly: return date.formatted(Self.yearOnlyStyle)
        }
    }

    // MARK: - Age

    /// Returns the age in whole years from this date to today, or to `deathDate` if provided.
    ///
    /// Intended for use where `self` is a birthdate.
    public func age(deathDate: FuzzyDate? = nil) -> Int? {
        let end = deathDate?.date ?? Date.now
        return Self.yearsBetween(from: date, to: end)
    }

    /// Returns the age in whole years from this date to `referenceDate`.
    ///
    /// Intended for use where `self` is a birthdate.
    public func age(at referenceDate: FuzzyDate) -> Int? {
        Self.yearsBetween(from: date, to: referenceDate.date)
    }

    // MARK: - Private Parsing

    private struct ParseResult {
        let date: Date
        let precision: Precision
    }

    private static func parseWithPrecision(_ string: String) -> ParseResult? {

        // 1. ISO 8601 timestamp
        if let date = iso8601Formatter.date(from: string) {
            return ParseResult(date: date, precision: .full)
        }

        // 2. yyyy-MM-dd or yyyy/MM/dd
        if let date = yyyyMMddDash.date(from: string) {
            return ParseResult(date: date, precision: .full)
        }
        if let date = yyyyMMddSlash.date(from: string) {
            return ParseResult(date: date, precision: .full)
        }

        // 3. yyyy-MM or yyyy/MM
        if let date = yyyyMMDash.date(from: string) {
            return ParseResult(date: date, precision: .yearMonth)
        }
        if let date = yyyyMMSlash.date(from: string) {
            return ParseResult(date: date, precision: .yearMonth)
        }

        // 4. Four-digit year only
        if string.count == 4, let date = yyyy.date(from: string) {
            return ParseResult(date: date, precision: .yearOnly)
        }

        // 5. US/EU day-month-year formats
        if let date = parseDayMonthYear(string) {
            return ParseResult(date: date, precision: .full)
        }

        return nil
    }

    /// Resolves US (MM-dd-yyyy) vs EU (dd-MM-yyyy) ambiguity.
    ///
    /// If first component > 12, it must be a day → EU format.
    /// If second component > 12, it must be a day → US format.
    /// If both ≤ 12, US format is assumed.
    private static func parseDayMonthYear(_ string: String) -> Date? {
        let separator: Character = string.contains("/") ? "/" : "-"
        let parts = string.split(separator: separator)

        guard parts.count == 3,
              let first = Int(parts[0]),
              let second = Int(parts[1]),
              let year = Int(parts[2]),
              year >= 1900, year <= 2100
        else { return nil }

        let normalized = string.replacingOccurrences(of: "/", with: "-")

        if first > 12 {
            return ddMMyyyyDash.date(from: normalized)
        }
        if second > 12 {
            return mmDDyyyyDash.date(from: normalized)
        }
        return mmDDyyyyDash.date(from: normalized)
    }

    // MARK: - Display Styles

    /// All dates are parsed in UTC, so display styles must also use UTC
    /// to avoid the local timezone shifting the date by a day.
    private static let fullDateStyle: Date.FormatStyle = {
        var style = Date.FormatStyle.dateTime.month(.wide).day().year()
        style.timeZone = TimeZone(identifier: "UTC")!
        return style
    }()

    private static let monthYearStyle: Date.FormatStyle = {
        var style = Date.FormatStyle.dateTime.month(.wide).year()
        style.timeZone = TimeZone(identifier: "UTC")!
        return style
    }()

    private static let yearOnlyStyle: Date.FormatStyle = {
        var style = Date.FormatStyle.dateTime.year()
        style.timeZone = TimeZone(identifier: "UTC")!
        return style
    }()

    // MARK: - Formatters

    /// DateFormatter and ISO8601DateFormatter are not Sendable but these
    /// instances are immutable after initialization and never mutated.
    private nonisolated(unsafe) static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func makeDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.isLenient = false
        return formatter
    }

    private static func yearsBetween(from start: Date, to end: Date) -> Int? {
        let years = Calendar.current.dateComponents([.year], from: start, to: end).year
        guard let years, years >= 0 else { return nil }
        return years
    }

    private static let yyyyMMddDash = makeDateFormatter("yyyy-MM-dd")
    private static let yyyyMMddSlash = makeDateFormatter("yyyy/MM/dd")
    private static let yyyyMMDash = makeDateFormatter("yyyy-MM")
    private static let yyyyMMSlash = makeDateFormatter("yyyy/MM")
    private static let yyyy = makeDateFormatter("yyyy")
    private static let mmDDyyyyDash = makeDateFormatter("MM-dd-yyyy")
    private static let ddMMyyyyDash = makeDateFormatter("dd-MM-yyyy")
}
