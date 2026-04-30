//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

@Suite("FuzzyDate")
struct FuzzyDateTests {

    // MARK: - Helpers

    private static let utc = TimeZone(identifier: "UTC")!

    private func components(from date: Date) -> DateComponents {
        Calendar.current.dateComponents(in: Self.utc, from: date)
    }

    // MARK: - Parsing: Format Families

    @Test func `yyyy-MM-dd dash init`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `yyyy-MM-dd slash init`() throws {
        let fd = try #require(FuzzyDate("2024/06/15"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `yyyy-MM dash init`() throws {
        let fd = try #require(FuzzyDate("2024-06"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 1)
    }

    @Test func `yyyy-MM slash init`() throws {
        let fd = try #require(FuzzyDate("2024/06"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 1)
    }

    @Test func `year only init`() throws {
        let fd = try #require(FuzzyDate("2024"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 1)
        #expect(c.day == 1)
    }

    @Test func `iso8601 timestamp init`() throws {
        let fd = try #require(FuzzyDate("2024-06-15T00:00:00Z"))
        let c = components(from: fd.date)
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `us MM-dd-yyyy init`() throws {
        let fd = try #require(FuzzyDate("06-15-2024"))
        let c = components(from: fd.date)
        #expect(c.month == 6)
        #expect(c.day == 15)
        #expect(c.year == 2024)
    }

    @Test func `eu day above 12 init`() throws {
        let fd = try #require(FuzzyDate("15-06-2024"))
        let c = components(from: fd.date)
        #expect(c.day == 15)
        #expect(c.month == 6)
        #expect(c.year == 2024)
    }

    @Test func `ambiguous defaults to US`() throws {
        // Both 03 and 05 are ≤ 12, so US (MM-dd) is assumed
        let fd = try #require(FuzzyDate("03-05-2024"))
        let c = components(from: fd.date)
        #expect(c.month == 3)
        #expect(c.day == 5)
    }

    @Test func `unparseable returns nil`() {
        #expect(FuzzyDate("not a date") == nil)
        #expect(FuzzyDate("") == nil)
        #expect(FuzzyDate("   ") == nil)
    }

    // MARK: - Precision

    @Test func `precision full for yyyy-MM-dd`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        #expect(fd.precision == .full)
    }

    @Test func `precision full for iso8601 timestamp`() throws {
        let fd = try #require(FuzzyDate("2024-06-15T00:00:00Z"))
        #expect(fd.precision == .full)
    }

    @Test func `precision full for US format`() throws {
        let fd = try #require(FuzzyDate("06-15-2024"))
        #expect(fd.precision == .full)
    }

    @Test func `precision full for EU format`() throws {
        let fd = try #require(FuzzyDate("15-06-2024"))
        #expect(fd.precision == .full)
    }

    @Test func `precision yearMonth for yyyy-MM dash`() throws {
        let fd = try #require(FuzzyDate("2024-06"))
        #expect(fd.precision == .yearMonth)
    }

    @Test func `precision yearMonth for yyyy-MM slash`() throws {
        let fd = try #require(FuzzyDate("2024/06"))
        #expect(fd.precision == .yearMonth)
    }

    @Test func `precision yearOnly for yyyy`() throws {
        let fd = try #require(FuzzyDate("2024"))
        #expect(fd.precision == .yearOnly)
    }

    // MARK: - rawValue

    @Test func `rawValue stores trimmed input`() throws {
        let fd = try #require(FuzzyDate("  2024-06-15  "))
        #expect(fd.rawValue == "2024-06-15")
    }

    @Test func `rawValue stores exact input when no trimming needed`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        #expect(fd.rawValue == "2024-06-15")
    }

    @Test func `rawValue stores year only input`() throws {
        let fd = try #require(FuzzyDate("2024"))
        #expect(fd.rawValue == "2024")
    }

    // MARK: - Comparable

    @Test func `yearOnly less than yearMonth for same conceptual date`() throws {
        // "2024" and "2024-01" both parse to Jan 1, 2024; yearOnly < yearMonth
        let yearOnly = try #require(FuzzyDate("2024"))
        let yearMonth = try #require(FuzzyDate("2024-01"))
        #expect(yearOnly < yearMonth)
        #expect(yearOnly <= yearMonth)
        #expect(!(yearMonth < yearOnly))
    }

    @Test func `yearMonth less than full for same conceptual date`() throws {
        // "2024-01" and "2024-01-01" both parse to Jan 1, 2024; yearMonth < full
        let yearMonth = try #require(FuzzyDate("2024-01"))
        let full = try #require(FuzzyDate("2024-01-01"))
        #expect(yearMonth < full)
        #expect(!(full < yearMonth))
    }

    @Test func `yearOnly less than full for same conceptual date`() throws {
        let yearOnly = try #require(FuzzyDate("2024"))
        let full = try #require(FuzzyDate("2024-01-01"))
        #expect(yearOnly < full)
    }

    @Test func `different years sort correctly across precisions`() throws {
        let y2023 = try #require(FuzzyDate("2023"))
        let ym2024 = try #require(FuzzyDate("2024-06"))
        let full2025 = try #require(FuzzyDate("2025-03-15"))
        #expect(y2023 < ym2024)
        #expect(ym2024 < full2025)
        #expect(y2023 < full2025)
    }

    @Test func `sorting a mixed array produces correct order`() throws {
        let dates = [
            try #require(FuzzyDate("2024-06-15")),
            try #require(FuzzyDate("2024")),
            try #require(FuzzyDate("2023-12")),
            try #require(FuzzyDate("2024-01-01")),
        ]
        let sorted = dates.sorted()
        #expect(sorted[0].rawValue == "2023-12")
        #expect(sorted[1].rawValue == "2024")
        // 2024-01-01 (full) > 2024-01 which ties with "2024" (yearOnly).
        // "2024" parses to Jan 1, 2024 = same date as "2024-01-01",
        // yearOnly(0) < full(2), so "2024" < "2024-01-01"
        #expect(sorted[2].rawValue == "2024-01-01")
        #expect(sorted[3].rawValue == "2024-06-15")
    }

    // MARK: - Hashable

    @Test func `two values from the same string are equal`() throws {
        let a = try #require(FuzzyDate("2024-06-15"))
        let b = try #require(FuzzyDate("2024-06-15"))
        #expect(a == b)
    }

    @Test func `two values from the same string have the same hash`() throws {
        let a = try #require(FuzzyDate("2024-06-15"))
        let b = try #require(FuzzyDate("2024-06-15"))
        #expect(a.hashValue == b.hashValue)
    }

    @Test func `values from different strings are not equal`() throws {
        let a = try #require(FuzzyDate("2024-06-15"))
        let b = try #require(FuzzyDate("2024-06-16"))
        #expect(a != b)
    }

    @Test func `usable as dictionary key`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        var dict: [FuzzyDate: String] = [:]
        dict[fd] = "test"
        #expect(dict[fd] == "test")
    }

    // MARK: - Codable

    @Test func `codable round-trip preserves all properties`() throws {
        let original = try #require(FuzzyDate("2024-06-15"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FuzzyDate.self, from: data)
        #expect(decoded.rawValue == original.rawValue)
        #expect(decoded.date == original.date)
        #expect(decoded.precision == original.precision)
    }

    @Test func `codable round-trip for year-month`() throws {
        let original = try #require(FuzzyDate("2024-06"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FuzzyDate.self, from: data)
        #expect(decoded.rawValue == "2024-06")
        #expect(decoded.precision == .yearMonth)
    }

    @Test func `codable round-trip for year only`() throws {
        let original = try #require(FuzzyDate("2024"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FuzzyDate.self, from: data)
        #expect(decoded.rawValue == "2024")
        #expect(decoded.precision == .yearOnly)
    }

    @Test func `encoding writes rawValue as JSON string`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        let data = try JSONEncoder().encode(fd)
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString == "\"2024-06-15\"")
    }

    @Test func `decoding unparseable string throws DecodingError`() {
        let data = Data("\"not-a-date\"".utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(FuzzyDate.self, from: data)
        }
    }

    // MARK: - Display Strings

    @Test func `displayString full date matches parser`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        #expect(fd.displayString == FuzzyDateParser.displayString(from: "2024-06-15"))
        #expect(fd.displayString == "June 15, 2024")
    }

    @Test func `displayString year-month matches parser`() throws {
        let fd = try #require(FuzzyDate("2024-06"))
        #expect(fd.displayString == FuzzyDateParser.displayString(from: "2024-06"))
        #expect(fd.displayString == "June 2024")
    }

    @Test func `displayString year only matches parser`() throws {
        let fd = try #require(FuzzyDate("2024"))
        #expect(fd.displayString == FuzzyDateParser.displayString(from: "2024"))
        #expect(fd.displayString == "2024")
    }

    @Test func `displayString historical date`() throws {
        let fd = try #require(FuzzyDate("1995-03-15"))
        #expect(fd.displayString == "March 15, 1995")
    }

    @Test func `monthYearString full date matches parser`() throws {
        let fd = try #require(FuzzyDate("2024-06-15"))
        #expect(fd.monthYearString == FuzzyDateParser.monthYearString(from: "2024-06-15"))
        #expect(fd.monthYearString == "June 2024")
    }

    @Test func `monthYearString year-month matches parser`() throws {
        let fd = try #require(FuzzyDate("2024-06"))
        #expect(fd.monthYearString == FuzzyDateParser.monthYearString(from: "2024-06"))
        #expect(fd.monthYearString == "June 2024")
    }

    @Test func `monthYearString year only matches parser`() throws {
        let fd = try #require(FuzzyDate("2024"))
        #expect(fd.monthYearString == FuzzyDateParser.monthYearString(from: "2024"))
        #expect(fd.monthYearString == "2024")
    }

    // MARK: - Age

    @Test func `age at full date`() throws {
        let birth = try #require(FuzzyDate("2000-01-01"))
        let ref = try #require(FuzzyDate("2025-06-15"))
        #expect(birth.age(at: ref) == 25)
    }

    @Test func `age before birthday this year`() throws {
        let birth = try #require(FuzzyDate("2000-12-31"))
        let ref = try #require(FuzzyDate("2025-06-15"))
        #expect(birth.age(at: ref) == 24)
    }

    @Test func `age at death`() throws {
        let birth = try #require(FuzzyDate("1970-06-15"))
        let death = try #require(FuzzyDate("2020-12-01"))
        #expect(birth.age(deathDate: death) == 50)
    }

    @Test func `age with year only birthdate`() throws {
        // Year-only defaults to Jan 1, so age at mid-2025 should be 25
        let birth = try #require(FuzzyDate("2000"))
        let ref = try #require(FuzzyDate("2025-06-15"))
        #expect(birth.age(at: ref) == 25)
    }

    @Test func `age at matches parser age at date`() throws {
        // Verify FuzzyDate.age(at:) produces the same result as the FuzzyDateParser shim
        let birth = try #require(FuzzyDate("2000-01-01"))
        let ref = try #require(FuzzyDate("2025-06-15"))
        let fromFuzzyDate = birth.age(at: ref)
        let fromParser = FuzzyDateParser.age(birthdate: "2000-01-01", atDate: "2025-06-15")
        #expect(fromFuzzyDate == fromParser)
    }
}
