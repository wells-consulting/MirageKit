//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - HEAD

public extension Labrador {

    /// Performs a HEAD request, returning only the HTTP response (no body).
    /// Useful for checking resource existence or reading response headers
    /// without downloading the body.
    func head(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> HTTPURLResponse {

        let (_, response) = try await request(
            url: url,
            method: .head,
            headers: headers,
            timeout: timeout,
            logging: logging,
        )

        return response
    }
}
