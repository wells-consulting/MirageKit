//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Best-effort parser for fuzzy calendar date strings.
///
/// All parsing logic lives in `FuzzyDate`. This type is a backward-compatible
/// shim so existing call sites continue to compile unchanged.
public enum FuzzyDateParser {

    // MARK: - Parsing

    /// Attempts to parse a fuzzy date string into a `Date`.
    /// Returns `nil` if the string cannot be parsed.
    public static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        return FuzzyDate(string)?.date
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
        FuzzyDate(string)?.displayString ?? string
    }

    /// Formats a fuzzy date string as "Month YYYY" (e.g. "June 2024").
    ///
    /// - "2024-06-15" → "June 2024"
    /// - "2024-06"    → "June 2024"
    /// - "2024"       → "2024"
    /// - Unparseable  → returns the original string unchanged
    public static func monthYearString(from string: String) -> String {
        FuzzyDate(string)?.monthYearString ?? string
    }

    // MARK: - Age & Span Calculations

    /// Returns a person's current age in whole years, or their age at death
    /// if `deathDate` is provided.
    public static func age(birthdate: String, deathDate: String? = nil) -> Int? {
        guard let birth = FuzzyDate(birthdate) else { return nil }
        let death = deathDate.flatMap { FuzzyDate($0) }
        return birth.age(deathDate: death)
    }

    /// Returns a person's age at a specific reference date.
    public static func age(birthdate: String, atDate referenceDate: String) -> Int? {
        guard let birth = FuzzyDate(birthdate),
              let ref = FuzzyDate(referenceDate)
        else { return nil }
        return birth.age(at: ref)
    }

    /// Returns the lifespan in whole years between birth and death.
    public static func lifespan(birthdate: String, deathDate: String) -> Int? {
        guard let birth = FuzzyDate(birthdate),
              let death = FuzzyDate(deathDate)
        else { return nil }
        return birth.age(at: death)
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
}
