//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public extension Range<Date> {

    var displayString: String {
        PrivateUtils.displayString(startDate: lowerBound, endDate: upperBound)
    }

    var debugString: String {
        "\(lowerBound.formatted(.iso8601)) ..< \(upperBound.formatted(.iso8601))"
    }

    var debugDurationString: String {
        Date.debugDurationString(from: lowerBound, to: upperBound)
    }

    var debugDurationDescriptionString: String {
        Date.debugDurationDescriptionString(from: lowerBound, to: upperBound)
    }
}

public extension ClosedRange<Date> {

    var displayString: String {
        PrivateUtils.displayString(startDate: lowerBound, endDate: upperBound)
    }

    var debugString: String {
        "\(lowerBound.formatted(.iso8601)) ... \(upperBound.formatted(.iso8601))"
    }

    var debugDurationString: String {
        Date.debugDurationString(from: lowerBound, to: upperBound)
    }

    var debugDurationDescriptionString: String {
        Date.debugDurationDescriptionString(from: lowerBound, to: upperBound.addingTimeInterval(-1.0))
    }
}

private enum PrivateUtils {

    static func displayString(startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current

        let lhs = startDate
        let rhs = endDate.addingTimeInterval(-1.0)

        let defaultDisplayName = "\(lhs.formatted(date: .abbreviated, time: .shortened)) – \(rhs.formatted(date: .abbreviated, time: .shortened))"

        let (lhsYear, lhsMonth, lhsWeek, lhsDay) = {
            let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: lhs)
            return (components.year, components.month, components.weekOfYear, components.day)
        }()

        let (rhsYear, rhsMonth, rhsWeek, rhsDay) = {
            let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: rhs)
            return (components.year, components.month, components.weekOfYear, components.day)
        }()

        guard let lhsYear, let rhsYear, let lhsMonth, let rhsMonth, let lhsWeek, let lhsDay else {
            return defaultDisplayName
        }

        // Same day
        if lhsYear == rhsYear, lhsMonth == rhsMonth, lhsDay == rhsDay {
            if calendar.isDateInToday(lhs) {
                return "Today"
            } else if calendar.isDateInYesterday(lhs) {
                return "Yesterday"
            } else {
                return startDate.formatted(date: .abbreviated, time: .omitted)
            }
        }

        // Same week
        if lhsYear == rhsYear, lhsWeek == rhsWeek {
            return defaultDisplayName
        }

        // Same month
        if lhsYear == rhsYear, lhsMonth == rhsMonth {
            return calendar.monthSymbols[lhsMonth - 1] + " \(lhsYear)"
        }

        // Same year
        if lhsYear == rhsYear {
            return String(lhsYear)
        }

        return defaultDisplayName
    }
}
