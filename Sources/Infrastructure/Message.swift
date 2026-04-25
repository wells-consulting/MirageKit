//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// A structured notice with summary text, optional details, and a tone
/// that indicates how it should be presented to the user.
public struct Message: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Localized notice text
    public let summary: String

    /// Additional details
    public let details: String?

    /// Title; typically used in UI for dialogs or alerts
    public let title: String?

    /// Notice kind; typically used to style text in UI
    public let kind: Kind

    // MARK: - Factory Methods

    /// Creates an informational notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Informational notice
    public static func info(
        summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .info)
    }

    /// Creates a warning notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Warning notice
    public static func warning(
        summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .warning)
    }

    /// Creates an error notice.
    ///
    /// - Parameters:
    ///     - summary: Notice text
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Error notice
    public static func error(
        summary: String,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        .init(summary: summary, details: details, title: title, kind: .error)
    }

    /// Creates an error notice from any `Error`.
    ///
    /// Title is inferred as follows: if title is supplied at call site, that
    /// title is used. If the title is not supplied and the error has a title,
    /// that title is used. Otherwise, the notice is created without a title.
    ///
    /// - Parameters:
    ///     - error: Any error
    ///     - details: Verbose and possibly debug text
    ///     - title: Notice title
    ///
    /// - Returns:
    ///     Error notice
    public static func error(
        _ error: any Error,
        details: String? = nil,
        title: String? = nil,
    ) -> Self {
        let message = (error as? (any MirageKitError))?.summary ?? error.localizedDescription
        let details = details ?? (error as? (any MirageKitError))?.details
        let title = title ?? ((error as? (any MirageKitError))?.title)
        return .init(summary: message, details: details, title: title, kind: .error)
    }

    /// Notice kind
    public enum Kind: Int, Equatable, Comparable, Codable, Sendable {

        case info
        case warning
        case error

        public var title: String {
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
