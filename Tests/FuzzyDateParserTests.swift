//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

@Suite("FuzzyDateParser")
struct FuzzyDateParserTests {

    // MARK: - Helpers

    private static let utc = TimeZone(identifier: "UTC")!

    private func components(from date: Date) -> DateComponents {
        Calendar.current.dateComponents(in: Self.utc, from: date)
    }

    // MARK: - Parsing: Standard Formats

    @Test func `yyyy-MM-dd dash`() throws {
        let date = FuzzyDateParser.date(from: "2024-06-15")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `yyyy-MM-dd slash`() throws {
        let date = FuzzyDateParser.date(from: "2024/06/15")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `yyyy-MM dash`() throws {
        let date = FuzzyDateParser.date(from: "2024-06")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 1)
    }

    @Test func `yyyy-MM slash`() throws {
        let date = FuzzyDateParser.date(from: "2024/06")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 1)
    }

    @Test func `year only`() throws {
        let date = FuzzyDateParser.date(from: "2024")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 1)
        #expect(c.day == 1)
    }

    @Test func `iso8601 timestamp`() throws {
        let date = FuzzyDateParser.date(from: "2024-06-15T00:00:00Z")
        let c = try components(from: #require(date))
        #expect(c.year == 2024)
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    // MARK: - Parsing: US/EU Formats

    @Test func `us format MM-dd-yyyy`() throws {
        let date = FuzzyDateParser.date(from: "06-15-2024")
        let c = try components(from: #require(date))
        #expect(c.month == 6)
        #expect(c.day == 15)
        #expect(c.year == 2024)
    }

    @Test func `eu format day above 12`() throws {
        let date = FuzzyDateParser.date(from: "15-06-2024")
        let c = try components(from: #require(date))
        #expect(c.day == 15)
        #expect(c.month == 6)
        #expect(c.year == 2024)
    }

    @Test func `ambiguous defaults to US`() throws {
        // Both 03 and 05 are ≤ 12, so US (MM-dd) is assumed
        let date = FuzzyDateParser.date(from: "03-05-2024")
        let c = try components(from: #require(date))
        #expect(c.month == 3)
        #expect(c.day == 5)
    }

    @Test func `us format with slash`() throws {
        let date = FuzzyDateParser.date(from: "06/15/2024")
        let c = try components(from: #require(date))
        #expect(c.month == 6)
        #expect(c.day == 15)
    }

    @Test func `eu format with slash`() throws {
        let date = FuzzyDateParser.date(from: "15/06/2024")
        let c = try components(from: #require(date))
        #expect(c.day == 15)
        #expect(c.month == 6)
    }

    // MARK: - Parsing: Edge Cases

    @Test func `empty string returns nil`() {
        #expect(FuzzyDateParser.date(from: "") == nil)
    }

    @Test func `whitespace only returns nil`() {
        #expect(FuzzyDateParser.date(from: "   ") == nil)
    }

    @Test func `garbage returns nil`() {
        #expect(FuzzyDateParser.date(from: "not a date") == nil)
    }

    @Test func `trims whitespace`() {
        let date = FuzzyDateParser.date(from: "  2024-06-15  ")
        #expect(date != nil)
    }

    // MARK: - Timezone Stability

    @Test func `date does not shift across timezones`() throws {
        // A date is the same everywhere on the planet — parse in UTC
        // and verify it stays the same day regardless of local timezone.
        let date = FuzzyDateParser.date(from: "1968-05-09")
        let c = try components(from: #require(date))
        #expect(c.year == 1968)
        #expect(c.month == 5)
        #expect(c.day == 9)
    }

    // MARK: - Display Formatting

    @Test func `display string full date`() {
        #expect(FuzzyDateParser.displayString(from: "2024-06-15") == "June 15, 2024")
    }

    @Test func `display string year month`() {
        #expect(FuzzyDateParser.displayString(from: "2024-06") == "June 2024")
    }

    @Test func `display string year only`() {
        #expect(FuzzyDateParser.displayString(from: "2024") == "2024")
    }

    @Test func `display string fallback`() {
        #expect(FuzzyDateParser.displayString(from: "unknown") == "unknown")
    }

    @Test func `display string historical date`() {
        #expect(FuzzyDateParser.displayString(from: "1995-03-15") == "March 15, 1995")
    }

    // MARK: - Month/Year Formatting

    @Test func `month year from full date`() {
        #expect(FuzzyDateParser.monthYearString(from: "2024-06-15") == "June 2024")
    }

    @Test func `month year from year month`() {
        #expect(FuzzyDateParser.monthYearString(from: "2024-06") == "June 2024")
    }

    @Test func `month year from year only`() {
        #expect(FuzzyDateParser.monthYearString(from: "2024") == "2024")
    }

    @Test func `month year fallback`() {
        #expect(FuzzyDateParser.monthYearString(from: "garbage") == "garbage")
    }

    // MARK: - Age Calculation

    @Test func `age from full birthdate`() {
        // Use a fixed reference to avoid test flakiness near birthdays
        let age = FuzzyDateParser.age(birthdate: "2000-01-01", atDate: "2025-06-15")
        #expect(age == 25)
    }

    @Test func `age before birthday this year`() {
        let age = FuzzyDateParser.age(birthdate: "2000-12-31", atDate: "2025-06-15")
        #expect(age == 24)
    }

    @Test func `age at death`() {
        let age = FuzzyDateParser.age(birthdate: "1970-06-15", deathDate: "2020-12-01")
        #expect(age == 50)
    }

    @Test func `age with year only birthdate`() {
        // Year-only defaults to Jan 1, so age at mid-2025 should be 25
        let age = FuzzyDateParser.age(birthdate: "2000", atDate: "2025-06-15")
        #expect(age == 25)
    }

    @Test func `age returns nil for garbage birthdate`() {
        #expect(FuzzyDateParser.age(birthdate: "garbage") == nil)
    }

    @Test func `age at date returns nil for bad reference`() {
        #expect(FuzzyDateParser.age(birthdate: "2000-01-01", atDate: "garbage") == nil)
    }

    // MARK: - Lifespan

    @Test func `lifespan calculation`() {
        let years = FuzzyDateParser.lifespan(birthdate: "1970-06-15", deathDate: "2020-12-01")
        #expect(years == 50)
    }

    @Test func `lifespan returns nil for missing death`() {
        #expect(FuzzyDateParser.lifespan(birthdate: "1970-06-15", deathDate: "garbage") == nil)
    }

    // MARK: - Year Span

    @Test func `year span en dash`() {
        #expect(FuzzyDateParser.yearSpan(from: "1995–2019") == 24)
    }

    @Test func `year span hyphen`() {
        #expect(FuzzyDateParser.yearSpan(from: "1995-2019") == 24)
    }

    @Test func `year span em dash`() {
        #expect(FuzzyDateParser.yearSpan(from: "2010—2020") == 10)
    }

    @Test func `year span present`() {
        let years = FuzzyDateParser.yearSpan(from: "2020–present")
        let expected = Calendar.current.component(.year, from: .now) - 2020
        #expect(years == expected)
    }

    @Test func `year span present case insensitive`() {
        #expect(FuzzyDateParser.yearSpan(from: "2020–Present") != nil)
    }

    @Test func `year span garbage returns nil`() {
        #expect(FuzzyDateParser.yearSpan(from: "active") == nil)
    }

    @Test func `year span no separator returns nil`() {
        #expect(FuzzyDateParser.yearSpan(from: "2020") == nil)
    }

    // MARK: - Label Formatting

    @Test func `age label living`() {
        let label = FuzzyDateParser.ageLabel(birthdate: "2000-01-01", deathDate: nil)
        #expect(label?.hasSuffix("years old") == true)
        #expect(label?.contains("deceased") == false)
    }

    @Test func `age label deceased`() {
        let label = FuzzyDateParser.ageLabel(birthdate: "1970-06-15", deathDate: "2020-12-01")
        #expect(label == "50 years old (deceased)")
    }

    @Test func `age at date label default context`() {
        let label = FuzzyDateParser.ageAtDateLabel(
            birthdate: "2000-01-01",
            referenceDate: "2025-06-15",
        )
        #expect(label == "Age 25 at date")
    }

    @Test func `age at date label custom context`() {
        let label = FuzzyDateParser.ageAtDateLabel(
            birthdate: "2000-01-01",
            referenceDate: "2025-06-15",
            context: "at filming",
        )
        #expect(label == "Age 25 at filming")
    }
}
