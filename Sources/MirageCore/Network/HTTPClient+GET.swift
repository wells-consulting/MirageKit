//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - GET

public extension HTTPClient {

    func get(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        let (data, _) = try await request(
            url: url,
            method: .get,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        )

        return data
    }

    func get<Output: Decodable>(
        _ url: URL,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .get,
            data: nil,
            outputType: Output.self,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }
}
