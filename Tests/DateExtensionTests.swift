//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Formatting

@Suite("Date - Formatting")
struct DateFormattingTests {

    @Test("iso8601 returns ISO 8601 string")
    func iso8601Format() {
        let date = Date(timeIntervalSince1970: 0)
        let result = date.iso8601
        #expect(result.contains("1970"))
    }

    @Test("shortDate returns date-only string")
    func shortDateFormat() {
        let date = Date(timeIntervalSince1970: 0)
        let result = date.shortDate
        #expect(!result.isEmpty)
    }

    @Test("shortDateTime returns date and time")
    func shortDateTimeFormat() {
        let date = Date(timeIntervalSince1970: 0)
        let result = date.shortDateTime
        #expect(!result.isEmpty)
    }

    @Test("shortTime returns time-only string")
    func shortTimeFormat() {
        let date = Date(timeIntervalSince1970: 0)
        let result = date.shortTime
        #expect(!result.isEmpty)
    }
}

// MARK: - Duration Strings

@Suite("Date - Duration Strings")
struct DateDurationStringTests {

    @Test("Sub-second duration shows milliseconds")
    func subSecondDuration() {
        let start = Date()
        let end = start.addingTimeInterval(0.5)
        let result = Date.durationString(from: start, to: end)
        #expect(result.contains("ms"))
    }

    @Test("Multi-second duration shows seconds")
    func multiSecondDuration() {
        let start = Date()
        let end = start.addingTimeInterval(2.5)
        let result = Date.durationString(from: start, to: end)
        #expect(result.contains("s"))
    }

    @Test("durationLabel shows relative description for days")
    func durationLabelDays() {
        let start = Date()
        let end = start.addingTimeInterval(86400 * 3)
        let result = Date.durationLabel(from: start, to: end)
        #expect(result.contains("3 days"))
    }

    @Test("durationLabel shows 'just now' for seconds")
    func durationLabelJustNow() {
        let start = Date()
        let end = start.addingTimeInterval(5)
        let result = Date.durationLabel(from: start, to: end)
        #expect(result == "just now")
    }

    @Test("durationLabel shows hours")
    func durationLabelHours() {
        let start = Date()
        let end = start.addingTimeInterval(7200)
        let result = Date.durationLabel(from: start, to: end)
        #expect(result.contains("2 hours"))
    }

    @Test("durationLabel shows singular unit")
    func durationLabelSingular() {
        let start = Date()
        let end = start.addingTimeInterval(86400)
        let result = Date.durationLabel(from: start, to: end)
        #expect(result.contains("1 day"))
        #expect(!result.contains("days"))
    }
}

// MARK: - Start Of

@Suite("Date - Start Of Convenience")
struct DateStartOfTests {

    @Test("startOfDay strips time component")
    func startOfDayStripsTime() {
        let date = Date()
        let start = date.startOfDay
        let calendar = Calendar.current
        #expect(calendar.component(.hour, from: start) == 0)
        #expect(calendar.component(.minute, from: start) == 0)
        #expect(calendar.component(.second, from: start) == 0)
    }

    @Test("startOfHour strips minutes and seconds")
    func startOfHourStripsMinutes() {
        let date = Date()
        if let start = date.startOfHour {
            let calendar = Calendar.current
            #expect(calendar.component(.minute, from: start) == 0)
            #expect(calendar.component(.second, from: start) == 0)
        }
    }

    @Test("startOfMinute strips seconds")
    func startOfMinuteStripsSeconds() {
        let date = Date()
        if let start = date.startOfMinute {
            let calendar = Calendar.current
            #expect(calendar.component(.second, from: start) == 0)
        }
    }

    @Test("startOfMonth is first of month")
    func startOfMonthFirstDay() {
        let date = Date()
        if let start = date.startOfMonth {
            let calendar = Calendar.current
            #expect(calendar.component(.day, from: start) == 1)
        }
    }
}

// MARK: - Adding Days

@Suite("Date - Adding Days")
struct DateAddingDaysTests {

    @Test("addingDays adds to self, not current date")
    func addingDaysUseSelf() {
        let epoch = Date(timeIntervalSince1970: 0)
        if let result = epoch.addingDays(1) {
            // Result should be near epoch + 1 day, not near today + 1 day
            let expectedInterval: TimeInterval = 86400
            let actualInterval = result.timeIntervalSince1970
            #expect(abs(actualInterval - expectedInterval) < 1)
        }
    }

    @Test("addingDays with zero returns same date")
    func addingZeroDays() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        if let result = date.addingDays(0) {
            #expect(abs(result.timeIntervalSince1970 - date.timeIntervalSince1970) < 1)
        }
    }

    @Test("addingDays with negative subtracts")
    func addingNegativeDays() {
        let date = Date(timeIntervalSince1970: 86400 * 10)
        if let result = date.addingDays(-3) {
            let expected = 86400.0 * 7
            #expect(abs(result.timeIntervalSince1970 - expected) < 1)
        }
    }
}

// MARK: - Number of Days Between

@Suite("Date - numberOfDaysBetween")
struct DateNumberOfDaysTests {

    @Test("Same date returns zero")
    func sameDateZero() {
        let date = Date()
        let result = Date.numberOfDaysBetween(date, date)
        #expect(result == 0)
    }

    @Test("One day apart returns 1")
    func oneDayApart() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 86400)
        let result = Date.numberOfDaysBetween(date1, date2)
        #expect(result == 1)
    }

    @Test("Negative days when reversed")
    func negativeDays() {
        let date1 = Date(timeIntervalSince1970: 86400)
        let date2 = Date(timeIntervalSince1970: 0)
        let result = Date.numberOfDaysBetween(date1, date2)
        #expect(result == -1)
    }
}

// MARK: - Date Range Extensions

@Suite("DateRange - Extensions")
struct DateRangeExtensionTests {

    @Test("Range durationString shows duration")
    func rangeDurationString() {
        let start = Date()
        let end = start.addingTimeInterval(0.5)
        let range = start..<end
        #expect(range.durationString.contains("ms"))
    }

    @Test("ClosedRange durationString shows duration")
    func closedRangeDurationString() {
        let start = Date()
        let end = start.addingTimeInterval(2.5)
        let range = start...end
        #expect(range.durationString.contains("s"))
    }

    @Test("Range displayString is not empty")
    func rangeDisplayString() {
        let start = Date()
        let end = start.addingTimeInterval(3600)
        let range = start..<end
        #expect(!range.displayString.isEmpty)
    }

    @Test("Range debugString contains ISO dates")
    func rangeDebugString() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let range = start..<end
        let result = range.debugString
        #expect(result.contains("..<"))
        #expect(result.contains("1970"))
    }

    @Test("ClosedRange debugString contains ellipsis operator")
    func closedRangeDebugString() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400)
        let range = start...end
        let result = range.debugString
        #expect(result.contains("..."))
        #expect(result.contains("1970"))
    }
}
