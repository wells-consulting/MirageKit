//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - PATCH

public extension HTTPClient {

    func patch(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func patch<Output: Decodable>(
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
            method: .patch,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }

    func patch(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            input: input,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func patch<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .patch,
            input: input,
            outputType: Output.self,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }
}
