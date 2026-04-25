//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct LabradorError: MirageKitError {

    // MARK: - Properties

    // MARK: Yikes conformance

    public let refcode: String?
    public let summary: String
    public let title: String?
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: LabradorError specific

    public let urlRequest: URLRequest?
    public let httpURLResponse: HTTPURLResponse?
    public let responseData: Data?
    public let responseBody: String?
    public let timing: Range<Date>?
    public var statusCode: Labrador.StatusCode? {
        if let statusCodeRawValue = httpURLResponse?.statusCode {
            Labrador.StatusCode(rawValue: statusCodeRawValue)
        } else {
            nil
        }
    }

    public func header(_ name: String) -> String? {
        httpURLResponse?.value(forHTTPHeaderField: name)
    }

    public func response<T: Decodable>(as type: T.Type) -> T? {
        guard let responseData else { return nil }
        return try? Jayson.shared.decode(T.self, from: responseData)
    }

    public var kind: ErrorKind {
        // Transient HTTP status codes (match RetryPolicy.defaultRetryCodes)
        if let statusCode {
            switch statusCode {
            case .requestTimeout, .tooManyRequests:
                return .transient
            case .badGateway, .serviceUnavailable, .gatewayTimeout:
                return .transient
            default:
                return .persistent
            }
        }
        // Transient URLError codes
        if let urlError = underlyingError as? Foundation.URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return .transient
            default:
                return .persistent
            }
        }
        return .persistent
    }

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlRequest: URLRequest? = nil,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseBody: String? = nil,
        timing: Range<Date>? = nil,
        refcode: String? = nil,
    ) {

        self.title = title ?? "HTTP Error"

        self.refcode = refcode
        self.summary = summary

        let truncatedBody = responseBody.map { String($0.prefix(2000)) }
        self.responseBody = truncatedBody
        if let truncatedBody, !truncatedBody.isEmpty {
            self.details = details.map { $0 + "\n" + truncatedBody } ?? truncatedBody
        } else {
            self.details = details
        }

        self.underlyingError = underlyingError
        self.userInfo = userInfo

        self.urlRequest = urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.timing = timing
    }

    init(
        summary: String,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        clientRequest: Labrador.ClientRequest,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseBody: String? = nil,
        timing: Range<Date>? = nil,
        refcode: String? = nil,
    ) {

        self.refcode = refcode
        self.title = title ?? "HTTP Error"
        self.summary = summary

        let truncatedBody = responseBody.map { String($0.prefix(2000)) }
        self.responseBody = truncatedBody
        if let truncatedBody, !truncatedBody.isEmpty {
            self.details = details.map { $0 + "\n" + truncatedBody } ?? truncatedBody
        } else {
            self.details = details
        }

        self.underlyingError = underlyingError
        self.userInfo = userInfo

        self.urlRequest = clientRequest.urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.timing = timing
    }

    // MARK: Factory Methods

    public static func noURL() -> any MirageKitError {
        LabradorError(
            summary: "Request has no URL.",
        )
    }
}
