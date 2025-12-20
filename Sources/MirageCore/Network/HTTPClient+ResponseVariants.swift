//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Response Variants

/// Overloads that return ``Response<Output>`` instead of bare `Output`,
/// giving callers access to response headers, status codes, etc.
public extension HTTPClient {

    func getWithResponse<Output: Decodable>(
        _ url: URL,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let payload: Payload? = nil

        let clientRequest = ClientRequest(
            url: url,
            method: .get,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func postWithResponse<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try jsonCoder.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func putWithResponse<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try jsonCoder.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .put,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func patchWithResponse<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try jsonCoder.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .patch,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func deleteWithResponse<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try jsonCoder.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(type(of: input))",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .delete,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }
}
