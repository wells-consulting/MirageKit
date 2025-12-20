//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public protocol MirageError: LocalizedError {

    // Required, user-facing

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

    var referenceCode: String? { get }
    var alertTitle: String? { get }
    var clarification: String? { get }
    var details: String? { get }
    var recoverySuggestion: String? { get }

    // Optional, developer-facing

    var diagnostics: String? { get }
    var underlyingErrors: [any Error]? { get }
    var userInfo: [String: any Sendable]? { get }

    // Client-side specialization

    func replacingAlertTitle(with newAlertTitle: String) -> Self
    func replacingReferenceCode(with newReferenceCode: String) -> Self
}

public extension MirageError {

    var errorDescription: String? {  // LocalizedError conformance
        summary
    }

    var summary: String {
        if let referenceCode {
            "Error \(referenceCode)\nThe details below might be helpful to diagnose the problem."
        } else {
            "\(Self.self)\nThe details below might be helpful to diagnose the problem."
        }
    }

    var diagnostics: String? {

        var lines = [String]()

        if let details {
            lines.append("Details: \(details)\n")
        }

        if let userInfo, !userInfo.isEmpty {
            lines.append("User Info: " + String(describing: userInfo) + "\n")
        }

        if let underlyingErrors, !underlyingErrors.isEmpty {
            for error in underlyingErrors {
                if
                    let mirageError = error as? MirageError,
                    let diagnostics = mirageError.diagnostics
                {
                    lines.append("Underlying Error: " + diagnostics)
                } else {
                    lines.append("Underlying Error: " + error.localizedDescription)
                }
            }
        }

        // If error bridges to NSError, add additional info.
        let nsError = self as NSError
        if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
            lines.append("\nDomain: \(nsError.domain), Code: \(nsError.code), User Info: \(String(describing: nsError.userInfo))")
        }

        return lines.joined(separator: "\n")
    }
}
