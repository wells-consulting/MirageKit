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
public extension Labrador {

    func getWithResponse<Output: Decodable>(
        _ url: URL,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let payload: Payload? = nil

        let clientRequest = ClientRequest(
            url: url,
            method: .get,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func postWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try json.encode(input, userInfo: userInfo)

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
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func putWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try json.encode(input, userInfo: userInfo)

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
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func patchWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try json.encode(input, userInfo: userInfo)

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
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func deleteWithResponse<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Output> {

        let data = try json.encode(input, userInfo: userInfo)

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
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithResponse(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    // MARK: - Data Response Variants

    /// POST raw data, returning the response with raw `Data`.
    func postWithResponse(
        _ url: URL,
        data: Data,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Data> {

        let payload = Payload(
            data: data,
            contentType: contentType,
            typeName: "\(Data.self)",
            summary: data.count.formatted(.byteCount(style: .memory)),
        )

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithDataResponse(clientRequest)
    }

    /// POST a multipart form, returning the response with raw `Data`.
    func postWithResponse(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Data> {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithDataResponse(clientRequest)
    }

    /// POST a URL-encoded form, returning the response with raw `Data`.
    func postWithResponse(
        _ url: URL,
        form: URLEncodedForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
    ) async throws -> Response<Data> {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await requestWithDataResponse(clientRequest)
    }
}
