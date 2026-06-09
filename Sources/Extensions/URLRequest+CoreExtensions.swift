//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.

public import Foundation

extension URLRequest {

    public func redactedHeaders() -> [String: String] {
        if let allHTTPHeaderFields {
            Self.redactHeaders(allHTTPHeaderFields)
        } else {
            [:]
        }
    }

    public static func redactHeaders(_ headers: [String: String]) -> [String: String] {

        let sensitiveNames: Set<String> = [
            "authorization",
            "proxy-authorization",
            "cookie",
            "set-cookie",
            "x-api-key",
            "api-key",
            "apikey",
            "x-auth-token",
            "x-access-token",
            "x-amz-security-token",
            "cf-access-jwt-assertion",
            "firebase-instance-id-token",
            "x-csrf-token",
            "x-xsrf-token"
        ]

        let suspiciousFragments = [
            "token",
            "secret",
            "password",
            "passwd",
            "credential",
            "auth",
            "jwt",
            "api-key",
            "apikey"
        ]

        return headers.reduce(into: [:]) { result, entry in
            let name = entry.key
            let value = entry.value

            let lowerName = name.lowercased()

            let shouldRedact =
                sensitiveNames.contains(lowerName) ||
                suspiciousFragments.contains(where: lowerName.contains) ||
                looksSensitive(value)

            result[name] = shouldRedact ? "<redacted>" : value
        }
    }

    private static func looksSensitive(_ value: String) -> Bool {

        if looksLikeJWT(value) { return true }
        if value.count > 128 { return true }

        let lower = value.lowercased()
        if lower.hasPrefix("bearer ") { return true }
        if lower.hasPrefix("basic ") { return true }

        return false
    }

    private static func looksLikeJWT(_ value: String) -> Bool {

        let parts = value.split(separator: ".")
        guard parts.count == 3 else { return false }

        return parts.allSatisfy { part in
            part.count >= 8 &&
            part.allSatisfy {
                $0.isLetter ||
                $0.isNumber ||
                $0 == "-" ||
                $0 == "_"
            }
        }
    }
}
