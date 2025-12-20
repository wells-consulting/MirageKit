//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct URLError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let refcode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recovery: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: URLerror specific

    public let urlString: String?
    public let urlComponents: URLComponents?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        refcode: String? = nil,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil
    ) {

        self.refcode = refcode
        self.alertTitle = alertTitle ?? "Mirage URL Error"

        // summary: "Error (Reference \(refcode))"
        self.clarification = clarification ?? "Failed to build URL."

        self.details = details
        self.recovery = recovery
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: Factory Methods

    static func urlMissingScheme(
        refcode: String? = nil,
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            refcode: refcode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a scheme.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlMissingHost(
        refcode: String? = nil,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            refcode: refcode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a host.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlInvalid(
        refcode: String? = nil,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            refcode: refcode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)'.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }
}
