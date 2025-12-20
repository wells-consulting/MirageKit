//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Common protocol for errors thrown.

public protocol MirageError: Error, Sendable {

    // Required, user-facing

    /// Short, opaque (non-technical) message. For example,
    /// 'Couldn't connect to the server.'.
    var summary: String { get }

    // Optional, user-facing

    //
    // #!/usr/bin/env bash
    //
    // CHARS='ABCDEFGHJKMNPQRSTUVWXY23456789'
    // CHAR_COUNT=${#CHARS}
    //
    // id=$(openssl rand 4 \
    //  | xxd -p \
    //  | fold -w2 \
    //  | while read -r byte; do
    //      idx=$((16#$byte % CHAR_COUNT))
    //      printf '%s' "${CHARS:idx:1}"
    //    done \
    //  | head -c 4)
    //
    // printf '%s' "$id" | pbcopy
    // echo "$id"
    //

    /// Reference code that uniquely identifies the error. Used
    /// by the developer to track down the point of origin.
    var refcode: String? { get }

    /// Dialog title for UI
    var alertTitle: String? { get }

    /// Slightly more technical info. For example, 'Error authenticating
    /// to server http://192.168.1.20. Username or password is incorrect.'
    var clarification: String? { get }

    /// Detailed reasoning for the error that would help a tech-savy
    /// user. It may, for example, include the HTTP status code.
    var details: String? { get }

    /// Suggestion for recovering or fixing this error.
    var recovery: String? { get }

    // Optional, developer-facing

    /// The originating errors.
    var underlyingErrors: [any Error]? { get }

    /// Unstructured data that might be useful for a client to
    /// silently handle the error in code.
    var userInfo: [String: any Sendable]? { get }
}

// MARK: - Default Implementations

public extension MirageError {

    /// Default summary.
    var summary: String {
        if let refcode {
            "Error (Reference \(refcode))"
        } else {
            "\(Self.self)"
        }
    }

    /// Default diagnostics.
    var diagnostics: String? {

        var lines = [String]()

        lines.append(MirageErrorUtils.describe(self, options: .verbose))

        if let underlyingErrors, !underlyingErrors.isEmpty {
            lines.append("\nUnderlying Errors:")
            for error in underlyingErrors {
                lines.append(MirageErrorUtils.describe(error, options: .verbose))
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Helpers

public enum MirageErrorUtils {

    public struct ErrorDescriptionOptions: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let details: Self = .init(rawValue: 1 << 1)
        public static let underlyingErrors: Self = .init(rawValue: 1 << 2)
        public static let recovery: Self = .init(rawValue: 1 << 3)
        public static let userInfo: Self = .init(rawValue: 1 << 4)
        public static let nsError: Self = .init(rawValue: 1 << 5)

        public static let minimal: Self = []

        public static let basic: Self = [
            .details,
        ]

        public static let verbose: Self = [
            .details,
            .underlyingErrors,
            .recovery,
            .userInfo,
            .nsError
        ]
    }

    public static func describe(
        _ error: any Error,
        options: ErrorDescriptionOptions
    ) -> String {

        var lines = [String]()

        if let mirageError = error as? (any MirageError) {
            lines.append(mirageError.summary)
            if let clarification = mirageError.clarification {
                lines.append(clarification)
            }
            if options.contains(.details), let details = mirageError.details {
                lines.append(details)
            }
            if options.contains(.recovery), let recovery = mirageError.recovery {
                lines.append(recovery)
            }
            if options.contains(.userInfo), let userInfo = mirageError.userInfo, !userInfo.isEmpty {
                lines.append("\n" + String(describing: userInfo))
            }
        } else {
            lines.append("\(error)")
        }

        if options.contains(.nsError) {
            let nsError = error as NSError
            if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
                lines.append("\nNSError: Domain \(nsError.domain), Code \(nsError.code), User Info  \(String(describing: nsError.userInfo))")
            }
        }

        return lines.joined(separator: "\n")
    }
}
