//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct HTTPError: MirageError {

    // MARK: - Properties

    // MARK: MirageError conformance

    public let refcode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recovery: String?
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

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        refcode: String? = nil,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlRequest: URLRequest? = nil,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseTimeRange: Range<Date>? = nil
    ) {

        self.refcode = refcode
        self.alertTitle = alertTitle ?? "Mirage HTTP Error"

        // summary: "Error (Reference \(refcode))"
        self.clarification =
            if let clarification {
                clarification
            } else if let statusCode = httpURLResponse?.httpClientStatusCode {
                "HTTP request failed with status \(statusCode.description)."
            } else {
                "HTTP request failed."
            }

        self.details = details
        self.recovery = recovery
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlRequest = urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
    }

    init(
        refcode: String,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        clientRequest: HTTPClient.ClientRequest,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseTimeRange: Range<Date>? = nil
    ) {

        self.refcode = refcode
        self.alertTitle = alertTitle ?? "Mirage HTTP Error"
        self.clarification =
            if let clarification {
                clarification
            } else if let statusCode = httpURLResponse?.httpClientStatusCode {
                "HTTP request failed with status \(statusCode.description)."
            } else {
                "HTTP request failed."
            }
        self.details = Self.composeDetailsString(
            clientRequest: clientRequest,
            httpURLResponse: httpURLResponse,
            responseData: responseData,
            responseTimeRange: responseTimeRange)
        self.recovery = recovery
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlRequest = clientRequest.urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
    }

    // MARK: Factory Methods

    public static func missingURL(refcode: String) -> any MirageError {
        HTTPError(
            refcode: refcode,
            clarification: "Network request failed.",
            details: "The network request couldn't be made because there is no URL.")
    }

    // MARK: - Helpers

    static func composeDetailsString(
        clientRequest: HTTPClient.ClientRequest,
        httpURLResponse: HTTPURLResponse?,
        responseData: Data?,
        responseTimeRange: Range<Date>?
    ) -> String {

        var lines: [String] = []

        if let methodRawValue = clientRequest.urlRequest.httpMethod, let method = HTTPClient.Method(rawValue: methodRawValue) {
            if let statusCodeRawValue = httpURLResponse?.statusCode,
               let statusCode = HTTPClient.StatusCode(rawValue: statusCodeRawValue)
            {
                lines.append("HTTP \(method.rawValue) failed with \(statusCode.description).")
            } else {
                lines.append("HTTP \(method.rawValue) failed.")
            }
        } else {
            lines.append("HTTP request failed.")
        }

        if let responseData {
            lines.append("Received " + responseData.count.formatted(.byteCount(style: .memory)) + " bytes.")
        }

        if let responseTimeRange {
            lines.append("Completed in \(responseTimeRange.debugDurationString).")
        }

        return lines.joined(separator: "\n")
    }
}
