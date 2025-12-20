//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - OPTIONS

public extension HTTPClient {

    /// Performs an OPTIONS request, returning the HTTP response.
    /// Useful for CORS preflight or discovering supported methods
    /// via the `Allow` response header.
    func options(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> HTTPURLResponse {

        let (_, response) = try await request(
            url: url,
            method: .options,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        )

        return response
    }
}
