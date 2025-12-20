//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Message text with additional context.
public struct Message: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Localized message text
    public let summary: String

    /// Message details
    public let details: String?

    /// Message title; typically used in UI for dialogs or alerts
    public let title: String?

    /// Messsage severity; typically used to style text in UI
    public let severity: Severity

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(summary)
        if let title { hasher.combine(title) }
        hasher.combine(severity.rawValue)
    }

    // MARK: - Factory Methods

    /// Helper method to create an informational messsage.
    ///
    /// - Parameters:
    ///     - summary: Message text
    ///     - details: Verbose and possibly debug text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Informational message
    public static func info(summary: String, details: String? = nil, title: String? = nil) -> Self {
        .init(summary: summary, details: details, title: title, severity: .info)
    }

    /// Helper method to create a warning messsage.
    ///
    /// - Parameters:
    ///     - summary: Message text
    ///     - details: Verbose and possibly debug text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Warning message
    public static func warning(summary: String, details: String? = nil, title: String? = nil) -> Self {
        .init(summary: summary, details: details, title: title, severity: .warning)
    }

    /// Helper method to create an error messsage.
    ///
    /// - Parameters:
    ///     - summary: Message text
    ///     - details: Verbose and possibly debug text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Error message
    public static func error(summary: String, details: String? = nil, title: String? = nil) -> Self {
        .init(summary: summary, details: details, title: title, severity: .error)
    }

    /// Helper method to create an error messsage.
    ///
    /// Title is inferred as follows: if title is supplied at call site, that
    /// title is used. If the title is not supplied and the error has a title,
    /// that title is used. Otherwise, the message is created without a title.
    ///
    /// - Parameters:
    ///     - error: Any error
    ///     - details: Verbose and possibly debug text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Informational message
    public static func error(_ error: any Error, details: String? = nil, title: String? = nil) -> Self {
        let message = (error as? (any MirageError))?.clarification ?? error.localizedDescription
        let details = details ?? (error as? (any MirageError))?.clarification ?? error.localizedDescription
        let title = title ?? ((error as? (any MirageError))?.alertTitle)
        return .init(summary: message, details: details, title: title, severity: .error)
    }

    /// Message severity
    public enum Severity: Int, Equatable, Comparable, Codable, Sendable {
        case info
        case warning
        case error

        public var title: String? {
            switch self {
            case .info:
                "Info"
            case .warning:
                "Warning"
            case .error:
                "Error"
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
