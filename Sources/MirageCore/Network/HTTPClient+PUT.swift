//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - PUT

public extension HTTPClient {

    func put(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .put,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func put<Output: Decodable>(
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
            method: .put,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }

    func put(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .put,
            input: input,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func put<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .put,
            input: input,
            outputType: Output.self,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }
}
