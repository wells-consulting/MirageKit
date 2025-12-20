//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct CSVError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let referenceCode: String?
    public let clarification: String?
    public let alertTitle: String?
    public let details: String?
    public let recoverySuggestion: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        referenceCode: String? = nil,
        clarification: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.referenceCode = referenceCode
        self.clarification = clarification ?? "Couldn't save CSV file."
        self.alertTitle = alertTitle ?? "Mirage CSV Error"
        self.details = details
        self.recoverySuggestion = recoverySuggestion
        self.userInfo = userInfo
        self.underlyingErrors = underlyingErrors
    }

    // MARK: Factory Methods

    static func saveTo(
        _ url: URL,
        data: Data, error: Error
    ) -> Self {

        .init(
            referenceCode: "DAFC",
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file to '\(url.absoluteString)'.",
            underlyingErrors: [error],
            userInfo: ["url": url])
    }

    static func saveToDownloadsFolder(
        filename: String,
        data: Data,
        error: Error
    ) -> Self {

        .init(
            referenceCode: "4XGP",
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file '\(filename)' to the downloads folder.",
            underlyingErrors: [error],
            userInfo: ["filename": filename])
    }

    // MARK: - Specialization

    public func replacingAlertTitle(with newAlertTitle: String) -> Self {
        .init(
            referenceCode: referenceCode,
            clarification: clarification,
            alertTitle: newAlertTitle,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo)
    }

    public func replacingReferenceCode(with newReferenceCode: String) -> Self {
        .init(
            referenceCode: newReferenceCode,
            clarification: clarification,
            alertTitle: alertTitle,
            details: details,
            recoverySuggestion: recoverySuggestion,
            underlyingErrors: underlyingErrors,
            userInfo: userInfo)
    }
}
