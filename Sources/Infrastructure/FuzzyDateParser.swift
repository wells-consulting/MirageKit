//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Best-effort parser for fuzzy calendar date strings.
///
/// Domain models store dates like `releaseDate`, `birthdate`, and `deathDate`
/// as `String?` because backends send them in varying formats ("2024-06-15",
/// "2024-06", "2024", ISO 8601 timestamps, etc.). This utility converts those
/// strings into `Date` values when needed (metadata items, display formatting).
///
/// Partial dates default to the earliest representable instant: year-only
/// becomes January 1, year-month becomes the 1st of that month.
public enum FuzzyDateParser {

    // MARK: - Parsing

    /// Attempts to parse a fuzzy date string into a `Date`.
    ///
    /// Supported formats (tried in order):
    /// 1. ISO 8601 with time ("2024-06-15T00:00:00Z")
    /// 2. "yyyy-MM-dd" or "yyyy/MM/dd"
    /// 3. "yyyy-MM" or "yyyy/MM"
    /// 4. "yyyy" (four-digit year only)
    /// 5. "MM-dd-yyyy" or "MM/dd/yyyy" (US) / "dd-MM-yyyy" (EU)
    ///
    /// For US/EU ambiguity (both components ≤ 12), US format is assumed.
    /// Returns `nil` if the string cannot be parsed.
    public static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        return parseWithPrecision(string)?.date
    }

    // MARK: - Display Formatting

    /// Formats a fuzzy date string for human display, preserving the
    /// precision of the original string.
    ///
    /// - "2024-06-15" → "June 15, 2024"
    /// - "2024-06"    → "June 2024"
    /// - "2024"       → "2024"
    /// - Unparseable  → returns the original string unchanged
    public static func displayString(from string: String) -> String {
        guard let result = parseWithPrecision(string) else {
            return string
        }
        switch result.precision {
        case .full:
            return result.date.formatted(fullDateStyle)
        case .yearMonth:
            return result.date.formatted(monthYearStyle)
        case .yearOnly:
            return result.date.formatted(yearOnlyStyle)
        }
    }

    /// Formats a fuzzy date string as "Month YYYY" (e.g. "June 2024").
    ///
    /// Useful for metadata contexts where only month and year are meaningful.
    ///
    /// - "2024-06-15" → "June 2024"
    /// - "2024-06"    → "June 2024"
    /// - "2024"       → "2024"
    /// - Unparseable  → returns the original string unchanged
    public static func monthYearString(from string: String) -> String {
        guard let result = parseWithPrecision(string) else {
            return string
        }
        switch result.precision {
        case .full, .yearMonth:
            return result.date.formatted(monthYearStyle)
        case .yearOnly:
            return result.date.formatted(yearOnlyStyle)
        }
    }

    // MARK: - Age & Span Calculations

    /// Returns a person's current age in whole years, or their age at death
    /// if `deathDate` is provided.
    ///
    /// - Parameters:
    ///   - birthdate: A fuzzy date string for the date of birth.
    ///   - deathDate: An optional fuzzy date string for the date of death.
    /// - Returns: Age in whole years, or `nil` if `birthdate` cannot be parsed.
    public static func age(birthdate: String, deathDate: String? = nil) -> Int? {
        guard let birth = date(from: birthdate) else { return nil }
        let end: Date = if let deathDate, let death = date(from: deathDate) {
            death
        } else {
            Date.now
        }
        return yearsBetween(from: birth, to: end)
    }

    /// Returns a person's age at a specific reference date (e.g. a scene's
    /// release date).
    ///
    /// - Parameters:
    ///   - birthdate: A fuzzy date string for the date of birth.
    ///   - referenceDate: A fuzzy date string for the reference point.
    /// - Returns: Age in whole years, or `nil` if either date cannot be parsed.
    public static func age(birthdate: String, atDate referenceDate: String) -> Int? {
        guard let birth = date(from: birthdate),
              let ref = date(from: referenceDate)
        else { return nil }
        return yearsBetween(from: birth, to: ref)
    }

    /// Returns the lifespan in whole years between birth and death.
    ///
    /// - Parameters:
    ///   - birthdate: A fuzzy date string for the date of birth.
    ///   - deathDate: A fuzzy date string for the date of death.
    /// - Returns: Lifespan in whole years, or `nil` if either date cannot be parsed.
    public static func lifespan(birthdate: String, deathDate: String) -> Int? {
        guard let birth = date(from: birthdate),
              let death = date(from: deathDate)
        else { return nil }
        return yearsBetween(from: birth, to: death)
    }

    /// Returns the number of whole years spanned by a year-range string
    /// like "2018–present" or "1995–2019".
    ///
    /// Parses the start and end years separated by an en-dash (–), em-dash (—),
    /// or hyphen (-). "present" (case-insensitive) is treated as the current year.
    ///
    /// - Returns: Duration in whole years, or `nil` if the string cannot be parsed.
    public static func yearSpan(from rangeString: String) -> Int? {
        let separators: [Character] = ["–", "—", "-"]
        guard let separator = rangeString.first(where: { separators.contains($0) }) else {
            return nil
        }
        let parts = rangeString.split(separator: separator)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let startYear = Int(parts[0])
        else { return nil }

        let endYear: Int
        if parts[1].caseInsensitiveCompare("present") == .orderedSame {
            endYear = Calendar.current.component(.year, from: .now)
        } else if let parsed = Int(parts[1]) {
            endYear = parsed
        } else {
            return nil
        }

        let span = endYear - startYear
        return span >= 0 ? span : nil
    }

    /// Formats an age with a contextual label.
    ///
    /// - For living persons: "28 years old"
    /// - For deceased persons: "50 years old (deceased)"
    /// - Returns `nil` if the birthdate cannot be parsed.
    public static func ageLabel(birthdate: String, deathDate: String? = nil) -> String? {
        guard let years = age(birthdate: birthdate, deathDate: deathDate) else {
            return nil
        }
        if deathDate != nil {
            return "\(years) years old (deceased)"
        } else {
            return "\(years) years old"
        }
    }

    /// Formats an age at a reference date, e.g. "Age 24 at date".
    ///
    /// - Returns `nil` if either date cannot be parsed.
    public static func ageAtDateLabel(birthdate: String, referenceDate: String, context: String = "at date") -> String? {
        guard let years = age(birthdate: birthdate, atDate: referenceDate) else {
            return nil
        }
        return "Age \(years) \(context)"
    }

    // MARK: - Private

    private enum Precision {
        case yearOnly
        case yearMonth
        case full
    }

    private struct ParseResult {
        let date: Date
        let precision: Precision
    }

    private static func parseWithPrecision(_ string: String) -> ParseResult? {

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 1. ISO 8601 timestamp
        if let date = iso8601Formatter.date(from: trimmed) {
            return ParseResult(date: date, precision: .full)
        }

        // 2. yyyy-MM-dd or yyyy/MM/dd
        if let date = yyyyMMddDash.date(from: trimmed) {
            return ParseResult(date: date, precision: .full)
        }
        if let date = yyyyMMddSlash.date(from: trimmed) {
            return ParseResult(date: date, precision: .full)
        }

        // 3. yyyy-MM or yyyy/MM
        if let date = yyyyMMDash.date(from: trimmed) {
            return ParseResult(date: date, precision: .yearMonth)
        }
        if let date = yyyyMMSlash.date(from: trimmed) {
            return ParseResult(date: date, precision: .yearMonth)
        }

        // 4. Four-digit year only
        if trimmed.count == 4, let date = yyyy.date(from: trimmed) {
            return ParseResult(date: date, precision: .yearOnly)
        }

        // 5. US/EU day-month-year formats
        if let date = parseDayMonthYear(trimmed) {
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

        let normalized = string
            .replacingOccurrences(of: "/", with: "-")

        if first > 12 {
            // First > 12 means it's the day → dd-MM-yyyy (EU)
            return ddMMyyyyDash.date(from: normalized)
        }

        if second > 12 {
            // Second > 12 means it's the day → MM-dd-yyyy (US)
            return mmDDyyyyDash.date(from: normalized)
        }

        // Both ≤ 12 — assume US
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

    /// Whole years between two dates using the current calendar.
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
