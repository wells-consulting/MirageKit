//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - DELETE

public extension HTTPClient {

    func delete(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .delete,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func delete<Output: Decodable>(
        _ url: URL,
        data: Data,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .delete,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }

    func delete(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .delete,
            input: input,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func delete<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String],
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .delete,
            input: input,
            outputType: Output.self,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }
}
