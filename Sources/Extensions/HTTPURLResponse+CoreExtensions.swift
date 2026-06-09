//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.

import Foundation

struct RedactedHTTPResponse {
    let statusCode: Int
    let url: String?
    let headers: [String: String]
}

extension HTTPURLResponse {

    func redactedHeaders() -> [String: String] {
         allHeaderFields
            .reduce(into: [String: String]())
                { result, entry in
                    guard let key = entry.key as? String else { return }
                    let value = String(describing: entry.value)
                    result[key] = redactResponseHeader(
                        name: key,
                        value: value
                    )
                }
    }

    public func redactResponseHeader(name: String, value: String) -> String {

        let lowerName = name.lowercased()

        switch lowerName {
        case "set-cookie":
            return "<redacted>"

        case "www-authenticate":
            // Usually safe to keep. Contains auth scheme
            // but not credentials.
            return value

        case "location":
            if let url = URL(string: value) {
                return url.redacted()
            }
            return value

        default:
            break
        }

        if lowerName.contains("token") ||
           lowerName.contains("secret") ||
           lowerName.contains("credential") {
            return "<redacted>"
        }

        return value
    }
}
