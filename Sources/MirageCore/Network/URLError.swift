//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct URLError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let referenceCode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recoverySuggestion: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: URLerror specific

    public let urlString: String?
    public let urlComponents: URLComponents?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        referenceCode: String?,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil
    ) {

        self.referenceCode = referenceCode
        self.alertTitle = alertTitle ?? "Mirage URL Error"
        self.clarification = clarification ?? "Failed to build URL."
        self.details = details
        self.recoverySuggestion = recoverySuggestion
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: Factory Methods

    static func urlMissingScheme(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a scheme.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlMissingHost(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a host.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlInvalid(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)'.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    // MARK: - Specialization

    public func replacingAlertTitle(with newAlertTitle: String) -> Self {
        .init(
            referenceCode: referenceCode,
            alertTitle: newAlertTitle,
            clarification: clarification,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo,
            urlString: urlString,
            urlComponents: urlComponents)
    }

    public func replacingReferenceCode(with newReferenceCode: String) -> Self {
        .init(
            referenceCode: newReferenceCode,
            alertTitle: alertTitle,
            clarification: clarification,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo,
            urlString: urlString,
            urlComponents: urlComponents)
    }
}
