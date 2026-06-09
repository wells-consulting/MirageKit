//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.

import Foundation

extension URL: LogTextProviding {
    
    public var logText: String {
        redacted()
    }

    public func redacted() -> String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return absoluteString
        }

        // Detect common signed URL schemes and nuke the entire query.
        if let items = components.queryItems {
            let names = Set(items.map { $0.name.lowercased() })

            let isAWSPresigned =
                names.contains("x-amz-signature") ||
                names.contains("x-amz-credential")

            let isGoogleSigned =
                names.contains("x-goog-signature") ||
                names.contains("x-goog-credential")

            let isAzureSAS =
                names.contains("sig") &&
                (names.contains("se") || names.contains("sp") || names.contains("sr"))

            if isAWSPresigned || isGoogleSigned || isAzureSAS {
                components.percentEncodedQuery = "<redacted-query>"
                return components.string ?? absoluteString
            }
        }

        let exactSensitiveNames: Set<String> = [
            "access_token",
            "refresh_token",
            "id_token",
            "token",
            "auth",
            "authorization",
            "bearer",
            "jwt",

            "api_key",
            "apikey",
            "api-key",
            "key",
            "secret",
            "client_secret",

            "password",
            "passwd",
            "pwd",

            "session",
            "sessionid",
            "session_id",

            "credential",
            "credentials",

            "signature",
            "sig",

            "code",

            "aws_access_key_id",
            "x-amz-signature",
            "x-amz-security-token",
            "x-goog-signature",
            "x-goog-credential"
        ]

        let suspiciousFragments = [
            "token",
            "secret",
            "password",
            "passwd",
            "pwd",
            "auth",
            "credential",
            "signature",
            "sig",
            "apikey",
            "api_key"
        ]

        components.queryItems = components.queryItems?.map { item in

            let key = item.name.lowercased()

            guard let value = item.value else {
                return item
            }

            let shouldRedact =
            exactSensitiveNames.contains(key) ||
            suspiciousFragments.contains(where: key.contains) ||
            looksLikeJWT(value) ||
            value.count > 64

            if shouldRedact {
                return URLQueryItem(name: item.name, value: "<redacted>")
            }

            return item
        }

        return components.string ?? absoluteString
    }

    private func looksLikeJWT(_ value: String) -> Bool {
        let parts = value.split(separator: ".")

        guard parts.count == 3 else {
            return false
        }

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
