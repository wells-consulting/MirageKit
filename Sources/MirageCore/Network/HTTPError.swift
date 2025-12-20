//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct HTTPError: MirageError {

    // MARK: - Properties

    // MARK: MirageError conformance

    public let refcode: String?
    public let summary: String
    public let alertTitle: String?
    public let details: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: HTTPError specific

    public let urlRequest: URLRequest?
    public let httpURLResponse: HTTPURLResponse?
    public let responseData: Data?
    public let responseTimeRange: Range<Date>?
    public var statusCode: HTTPClient.StatusCode? {
        if let statusCodeRawValue = httpURLResponse?.statusCode {
            HTTPClient.StatusCode(rawValue: statusCodeRawValue)
        } else {
            nil
        }
    }

    public func value(forHeader name: String) -> String? {
        httpURLResponse?.value(forHTTPHeaderField: name)
    }

    public func response<T: Decodable>(as type: T.Type) -> T? {
        guard let responseData else { return nil }
        return try? JSONCoder.shared.decode(T.self, from: responseData)
    }

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlRequest: URLRequest? = nil,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseTimeRange: Range<Date>? = nil,
        refcode: String? = nil,
    ) {

        self.alertTitle = alertTitle ?? "HTTP Error"

        self.refcode = refcode
        self.summary = summary
        self.details = details

        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlRequest = urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
    }

    init(
        summary: String,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        clientRequest: HTTPClient.ClientRequest,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseTimeRange: Range<Date>? = nil,
        refcode: String? = nil,
    ) {

        self.refcode = refcode
        self.alertTitle = alertTitle ?? "HTTP Error"
        self.summary = summary
        self.details = details

        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlRequest = clientRequest.urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
    }

    // MARK: Factory Methods

    public static func missingURL() -> any MirageError {
        HTTPError(
            summary: "Could not complete HTTP request because there is no URL.",
        )
    }
}
