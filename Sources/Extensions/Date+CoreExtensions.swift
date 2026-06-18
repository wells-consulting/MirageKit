//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Core Date extensions
public extension Date {

    // MARK: - Utility string formatting

    var iso8601: String {
        formatted(.iso8601)
    }

    var timestamp: String {
        formatted(.iso8601)
    }

    var shortDate: String {
        formatted(date: .numeric, time: .omitted)
    }

    var shortDateTime: String {
        formatted(date: .numeric, time: .shortened)
    }

    var shortTime: String {
        formatted(date: .omitted, time: .shortened)
    }

    var mediumDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Smart

    /// Smart format: "Mar 5" for dates within 11 months, "Jun 2024" for older dates.
    var smartFormatted: String {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.year, .month], from: now)
        let currentYear = components.year!
        let currentMonth = components.month!
        var cutoffMonth = currentMonth - 11
        var cutoffYear = currentYear
        if cutoffMonth < 1 {
            cutoffMonth += 12
            cutoffYear -= 1
        }
        let cutoff = calendar.date(from: DateComponents(year: cutoffYear, month: cutoffMonth, day: 1))!
        return if self >= cutoff {
            formatted(.dateTime.month(.abbreviated).day())
        } else {
            formatted(.dateTime.month(.abbreviated).year())
        }
    }

    // MARK: - Hour

    /// Format an hour (0–23) as a locale-appropriate time range label.
    static func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        guard let start = calendar.date(from: components) else {
            return "\(hour):00"
        }
        let style = Date.FormatStyle()
            .hour(.defaultDigits(amPM: .abbreviated))
        return start.formatted(style)
    }

    // MARK: - Weekday

    static func dates(from firstDate: Date, to finalDate: Date, interval: Calendar.Component = .day) -> [Date] {
        var dates: [Date] = []
        var current = firstDate
        while current <= finalDate {
            dates.append(current)
            current = Calendar.current.date(byAdding: interval, value: 1, to: current)!
        }
        return dates
    }

    /// Returns the weekday name for a weekday index (1 = Sunday in Calendar).
    static func weekdayLabel(_ weekday: Int) -> String {
        guard weekday >= 1 && weekday <= 7 else { return "\(weekday)?" }
        let symbols = Calendar.current.standaloneWeekdaySymbols
        let index = (weekday - 1) % symbols.count
        return symbols[index]
    }

    // MARK: - Duration Strings

    static func msDurationString(from startDate: Date, to endDate: Date) -> String {
        let elapsedTime = TimeInterval(endDate.timeIntervalSince(startDate))
        if elapsedTime < 1.0 {
            return String(format: "%dms", Int(ceil(elapsedTime * 1000.0)))
        } else {
            return String(format: "%1.2fs", elapsedTime)
        }
    }

    static func durationString(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let nowIsAfter = endDate > startDate
        let fromDate = nowIsAfter ? startDate : endDate
        let toDate = nowIsAfter ? endDate : startDate

        let components = calendar.dateComponents(
            [.year, .month, .weekOfYear, .day, .hour, .minute, .second],
            from: fromDate,
            to: toDate,
        )

        let timeString = if let year = components.year, year != 0 {
            "\(abs(year)) year" + (abs(year) == 1 ? "" : "s")
        } else if let month = components.month, month != 0 {
            "\(abs(month)) month" + (abs(month) == 1 ? "" : "s")
        } else if let week = components.weekOfYear, week != 0 {
            "\(abs(week)) week" + (abs(week) == 1 ? "" : "s")
        } else if let day = components.day, day != 0 {
            "\(abs(day)) day" + (abs(day) == 1 ? "" : "s")
        } else if let hour = components.hour, hour != 0 {
            "\(abs(hour)) hour" + (abs(hour) == 1 ? "" : "s")
        } else if let minute = components.minute, minute != 0 {
            "\(abs(minute)) minute" + (abs(minute) == 1 ? "" : "s")
        } else {
            "just now"
        }

        if timeString == "just now" {
            return timeString
        } else {
            return nowIsAfter ? "\(timeString) from now" : "\(timeString) ago"
        }
    }

    // MARK: - Convenience Properties

    var startOfMinute: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: components)
    }

    func startOfMinutes(_ numMinutes: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        guard let minute = components.minute else { return nil }
        components.minute = (minute / numMinutes) * numMinutes
        return calendar.date(from: components)
    }

    var startOfHour: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components)
    }

    var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }

    var startOfWeek: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)
    }

    var startOfMonth: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }

    var startOfYear: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)
    }

    func addingDays(_ numDays: Int) -> Date? {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.setValue(numDays, for: .day)
        return calendar.date(byAdding: dateComponents, to: self)
    }

    static func numberOfDaysBetween(_ date1: Date, _ date2: Date) -> Int? {
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: date1)
        let toDate = calendar.startOfDay(for: date2)
        let numberOfDays = calendar.dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day
    }
}
