//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Common protocol for errors thrown.

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

    var summary: String { get }

    // Optional, user-facing

    /// Dialog title for UI
    var alertTitle: String? { get }

    /// Detailed reasoning for the error that would help a tech-savy
    /// user. It may, for example, include the HTTP status code.
    var details: String? { get }

    // Optional, developer-facing

    /// The originating errors.
    var underlyingErrors: [any Error]? { get }

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

    /// Default refcode.
    var refcode: String? {
        nil
    }

    /// Default diagnostics.
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

        public static let summary: Self = .init(rawValue: 1 << 1)
        public static let details: Self = .init(rawValue: 1 << 2)
        public static let underlyingErrors: Self = .init(rawValue: 1 << 3)
        public static let userInfo: Self = .init(rawValue: 1 << 4)
        public static let nsError: Self = .init(rawValue: 1 << 5)

        public static let minimal: Self = [
            .summary,
        ]

        public static let basic: Self = [
            .summary,
            .details,
        ]

        public static let verbose: Self = [
            .summary,
            .details,
            .underlyingErrors,
            .userInfo,
            .nsError
        ]
    }

    public static func describe(
        _ error: any Error,
        options: ErrorDescriptionOptions,
        indenting indent: Int = 0
    ) -> String {

        var lines = [String]()

        let indentString = String(repeating: "    ", count: indent)
        if indent > 0 { lines.append("Underlying Error #\(indent) (\(type(of: error)))") }

        var adjustedOptions = options

        if indent != 0 {
            
            if let mirageError = error as? (any MirageError) {
                    lines.append(indentString + "\(mirageError.summary)")
                    if adjustedOptions.contains(.details), let details = mirageError.details {
                        lines.append(indentString + details)
                    }
                    if adjustedOptions.contains(.userInfo), let userInfo = mirageError.userInfo, !userInfo.isEmpty {
                        lines.append(indentString + String(describing: userInfo))
                    }
            } else {
                adjustedOptions.remove(.nsError)
                lines.append(indentString + "\(error)")
            }

            if adjustedOptions.contains(.nsError) {

                let nsError = error as NSError

                var include: Bool = true
                let domain = nsError.domain
                include = include && !domain.hasPrefix("MirageCore")
                include = include && (domain != "NSCocoaErrorDomain" || nsError.code != 0)

                if include {
                    var line = "Error Domain=\(domain), "
                    line += "Code=\(nsError.code)"
                    if !nsError.userInfo.isEmpty {
                        line += " \(String(describing: nsError.userInfo))"
                    }
                    lines.append(indentString + line)
                }
            }
        }

        let underlyingErrors = (error as? (any MirageError))?.underlyingErrors ?? []

        if !underlyingErrors.isEmpty {
            for underlyingError in underlyingErrors {
                lines.append("\n" +
                    Self.describe(
                        underlyingError,
                        options: options,
                        indenting: indent + 1
                    )
                )
            }
        }

        return lines.joined(separator: "\n")
    }
}
