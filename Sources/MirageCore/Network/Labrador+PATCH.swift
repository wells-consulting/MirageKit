//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - PATCH

public extension Labrador {

    func patch(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            headers: headers,
            timeout: timeout,
            logging: logging,
        ).0
    }

    func patch<Output: Decodable>(
        _ url: URL,
        data: Data,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .patch,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
        )
    }

    func patch(
        _ url: URL,
        body input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .patch,
            input: input,
            headers: headers,
            timeout: timeout,
            logging: logging,
        ).0
    }

    func patch<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .patch,
            input: input,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
        )
    }
}
