//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct EarlError: Yikes {

    // MARK: - Properties

    // MARK: Oops Conformance

    public let refcode: String?
    public let summary: String
    public let title: String?
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: EarlError specific

    public let urlString: String?
    public let urlComponents: URLComponents?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        summary: String? = nil,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil,
        refcode: String? = nil,
    ) {

        self.title = title ?? "URL Error"

        self.refcode = refcode
        self.summary = summary ?? "Invalid URL."

        self.details = details
        self.underlyingError = underlyingError
        self.userInfo = userInfo

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: Factory Methods

    static func missingScheme(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Missing scheme in \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func missingHost(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Missing host in \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }

    static func invalidURL(
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            summary: "Invalid URL \"\(urlString)\".",
            urlString: urlString,
            urlComponents: urlComponents,
        )
    }
}
