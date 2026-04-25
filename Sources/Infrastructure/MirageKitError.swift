//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Classifies errors by their expected recovery behavior.
public enum ErrorKind: String, Sendable {

    /// Transient failures that may succeed on retry (network timeout, temporary
    /// server error, rate limiting).
    case transient

    /// Persistent failures where retrying the same operation won't help without
    /// user intervention (bad credentials, missing resource, permission denied).
    case persistent

    /// Configuration errors where the user needs to change a setting before
    /// retrying (invalid URL, missing host, bad port).
    case configuration
}

/// Common protocol for errors thrown by MirageKit modules.

public protocol MirageKitError: Error, LocalizedError, CustomStringConvertible, Sendable {

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

    /// Classifies this error so consumers can determine appropriate
    /// recovery behavior (e.g. retry, prompt user, fix configuration).
    var kind: ErrorKind { get }
}

// MARK: - Default Implementations

public extension MirageKitError {

    /// Concise human-readable description for string interpolation.
    var description: String {
        var result = if let title {
            "\(title): \(summary)"
        } else {
            summary
        }
        if let refcode {
            result += " [\(refcode)]"
        }
        return result
    }

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
    var kind: ErrorKind { .persistent }

    /// Produce a human-readable diagnostic string for this error.
    func diagnostics(options: DoesNotCompute.Options) -> String? {
        DoesNotCompute.describe(self, options: options)
    }
}

// MARK: - Refcode

public enum Refcode {

    /// Derives a human-readable refcode from the call site.
    /// e.g. `"Scene.fetchData"` from a `#fileID` of `"App/Some+Scene.swift"`
    /// and a `#function` of `"fetchData(_:)"`.
    ///
    /// The domain is the file's stem with the module prefix and any base-class
    /// prefix (everything up to and including the last `+`) stripped, so that
    /// `Some+Scene` → `Scene` and `SomeViewModel` → `SomeViewModel`.
    public static func derive(fileID: String = #fileID, caller: String = #function) -> String {
        let file = String(fileID.split(separator: "/").last ?? Substring(fileID))
        var domain = file.replacingOccurrences(of: ".swift", with: "")
        if let plus = domain.lastIndex(of: "+") {
            domain = String(domain[domain.index(after: plus)...])
        }
        let method = String(caller.split(separator: "(").first ?? Substring(caller))
        return "\(domain).\(method)"
    }
}

// MARK: - Helpers

public enum DoesNotCompute {

    public struct Options: OptionSet, Sendable {

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
        options: Options,
        depth: Int = 0,
    ) -> String {

        var lines = [String]()

        let indent = String(repeating: "    ", count: depth)

        if let oops = error as? (any MirageKitError) {
            if depth > 0 {
                lines.append("Underlying Error (\(type(of: error)))")
            }
            lines.append(indent + oops.summary)
            if options.contains(.details), let details = oops.details {
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
            let skipNSError = domain.hasPrefix("MirageKit")
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
           let underlying = (error as? (any MirageKitError))?.underlyingError
        {
            lines.append(
                "\n" + Self.describe(underlying, options: options, depth: depth + 1),
            )
        }

        return lines.joined(separator: "\n")
    }
}
