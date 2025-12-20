//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JSONError: MirageError {

    public enum Process: Sendable {
        case encode
        case decode
    }

    // MARK: - Properties

    // MARK: MirageError conformance

    public let referenceCode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recoverySuggestion: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: JSONError specific

    public let process: Process
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

    private init(
        process: Process,
        referenceCode: String?,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        jsonText: String? = nil,
    ) {
        self.process = process
        self.referenceCode = referenceCode
        self.alertTitle = alertTitle
        self.clarification = clarification
        self.details = details
        self.recoverySuggestion = recoverySuggestion
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo
        self.jsonText = jsonText
    }

    public init(
        process: Process,
        referenceCode: String?,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
    ) {

        self.referenceCode = referenceCode
        self.alertTitle = alertTitle ?? "Mirage JSON Error"
        self.clarification =
            if let clarification {
                clarification
            } else {
                switch process {
                case .decode:
                    "JSON decoding failed."
                case .encode:
                    "JSON encoding failed."
                }
            }
        self.details =
            if let details {
                details
            } else {
                switch process {
                case .encode:
                    "Could not encode value."
                case .decode:
                    "Could not decode value."
                }
        }
        self.recoverySuggestion = recoverySuggestion
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.process = process
        self.jsonText =
            if let data {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
    }

    // MARK: - Specialization

    public func replacingAlertTitle(with newAlertTitle: String) -> Self {
        .init(
            process: process,
            referenceCode: referenceCode,
            alertTitle: newAlertTitle,
            clarification: clarification,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo,
            jsonText: jsonText)
    }

    public func replacingReferenceCode(with newReferenceCode: String) -> Self {
        .init(
            process: process,
            referenceCode: newReferenceCode,
            alertTitle: alertTitle,
            clarification: clarification,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo,
            jsonText: jsonText)
    }
}
