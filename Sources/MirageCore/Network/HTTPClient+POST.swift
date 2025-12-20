//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - POST

public extension HTTPClient {

    func post(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func post(
        _ url: URL,
        data: Data,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

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
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
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
            method: .post,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }

    func post(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            input: input,
            headers: headers,
            timeout: timeout,
            logOptions: logOptions,
        ).0
    }

    func post<Output: Decodable>(
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
            method: .post,
            input: input,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logOptions: logOptions,
        )
    }

    // MARK: MultipartForm

    func post(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        let payload = payload(for: form)

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

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: MultipartForm,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

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

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo,
        )
    }

    // MARK: URLEncodedForm

    func post(
        _ url: URL,
        form: URLEncodedForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: URLEncodedForm,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

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

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo,
        )
    }
}
