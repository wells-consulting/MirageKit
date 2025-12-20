//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct URLError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let refcode: String?
    public let summary: String
    public let alertTitle: String?
    public let details: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: URLerror specific

    public let urlString: String?
    public let urlComponents: URLComponents?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        summary: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil,
        refcode: String? = nil,
    ) {

        self.alertTitle = alertTitle ?? "URL Error"

        self.refcode = refcode
        self.summary = summary ?? "Could not build URL."

        self.details = details
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: Factory Methods

    static func urlMissingScheme(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Could not create a URL from \"\(urlString)\" because it is missing a scheme.",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func urlMissingHost(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Could not create a URL from \"\(urlString)\" because it is missing a host.",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func urlInvalid(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Could not create a URL from \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }
}
