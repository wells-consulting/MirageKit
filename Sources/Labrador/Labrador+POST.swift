//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - POST

public extension Labrador {

    func post(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    func post(
        _ url: URL,
        data: Data,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
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
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
            logContext: logContext,
        )

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        data: Data,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .post,
            data: data,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    func post(
        _ url: URL,
        body input: some Encodable,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        try await request(
            url: url,
            method: .post,
            input: input,
            headers: headers,
            timeout: timeout,
            logging: logging,
            logContext: logContext,
        ).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        body input: some Encodable,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        try await request(
            url: url,
            method: .post,
            input: input,
            outputType: outputType,
            headers: headers,
            timeout: timeout,
            userInfo: userInfo,
            logging: logging,
            logContext: logContext,
        )
    }

    // MARK: MultipartForm

    func post(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
            logContext: logContext,
        )

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: MultipartForm,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
            logContext: logContext,
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
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Data? {

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
            logContext: logContext,
        )

        return try await request(clientRequest).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: URLEncodedForm,
        as outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logging: LogOptions? = nil,
        logContext: String? = nil,
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            logOptions: logging,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
            logContext: logContext,
        )

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo,
        )
    }
}
