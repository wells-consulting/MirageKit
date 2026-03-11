//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Common protocol for errors thrown by MirageKit modules.

public protocol MirageError: Error, LocalizedError, Sendable {

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
    //      printf '%s' "${CHARS:idx:1}"r
    //    done \
    //  | head -c 4)
    //
    // printf '%s' "$id" | pbcopy
    // echo "$id"
    //

    /// Reference code that uniquely identifies the error. Used
    /// by the developer to track down the point of origin.
    var refcode: String? { get }

    // Required, user-facing

    /// A concise description of what went wrong.
    var summary: String { get }

    // Optional, user-facing

    /// A short title categorizing the error (e.g. "HTTP Error", "Decoding Error").
    var title: String? { get }

    /// Detailed reasoning for the error that would help a tech-savvy
    /// user. It may, for example, include the HTTP status code.
    var details: String? { get }

    // Optional, developer-facing

    /// The originating error, if this error wraps another.
    var underlyingError: (any Error)? { get }

    /// Unstructured data that might be useful for a client to
    /// silently handle the error in code.
    var userInfo: [String: any Sendable]? { get }
}

// MARK: - Default Implementations

public extension MirageError {

    /// Default LocalizedError
    var errorDescription: String? {
        if let details {
            summary + "\n" + details
        } else {
            summary
        }
    }

    var refcode: String? { nil }
    var title: String? { nil }
    var details: String? { nil }
    var underlyingError: (any Error)? { nil }
    var userInfo: [String: any Sendable]? { nil }

    /// Produce a human-readable diagnostic string for this error.
    func diagnostics(options: MirageErrorUtils.ErrorDescriptionOptions) -> String? {
        MirageErrorUtils.describe(self, options: options)
    }
}

// MARK: - Helpers

public enum MirageErrorUtils {

    public struct ErrorDescriptionOptions: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let details: Self = .init(rawValue: 1 << 2)
        public static let underlyingError: Self = .init(rawValue: 1 << 3)
        public static let nsError: Self = .init(rawValue: 1 << 5)

        public static let minimal: Self = []

        public static let basic: Self = [
            .details,
        ]

        public static let verbose: Self = [
            .details,
            .underlyingError,
            .nsError,
        ]
    }

    public static func describe(
        _ error: any Error,
        options: ErrorDescriptionOptions,
        depth: Int = 0,
    ) -> String {

        var lines = [String]()

        let indent = String(repeating: "    ", count: depth)

        if let mirageError = error as? (any MirageError) {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: error)))")
            }
            lines.append(indent + mirageError.summary)
            if options.contains(.details), let details = mirageError.details {
                lines.append(indent + details)
            }
        } else {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: error)))")
            }
            lines.append(indent + "\(error)")
        }

        if options.contains(.nsError) {
            let nsError = error as NSError
            let domain = nsError.domain
            let skipNSError = domain.hasPrefix("MirageCore")
                || (domain == "NSCocoaErrorDomain" && nsError.code == 0)

            if !skipNSError {
                var line = "Error Domain=\(domain), Code=\(nsError.code)"
                if !nsError.userInfo.isEmpty {
                    line += " \(String(describing: nsError.userInfo))"
                }
                lines.append(indent + line)
            }
        }

        if options.contains(.underlyingError),
           let underlying = (error as? (any MirageError))?.underlyingError
        {
            lines.append(
                "\n" + Self.describe(underlying, options: options, depth: depth + 1),
            )
        }

        return lines.joined(separator: "\n")
    }
}
