//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct CSVError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let refcode: String?
    public let summary: String
    public let alertTitle: String?
    public let details: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        refcode: String? = nil,
    ) {
        self.refcode = refcode
        self.summary = summary ?? "Could not save CSV file."
        self.alertTitle = alertTitle ?? "CSV Error"
        self.details = details
        self.userInfo = userInfo
        self.underlyingErrors = underlyingErrors
    }

    // MARK: Factory Methods

    static func saveTo(
        _ url: URL,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Could not save \(data.count.formatted(.byteCount(style: .file))) CSV file to \"\(url.absoluteString)\".",
            underlyingErrors: [error],
            userInfo: ["url": url])
    }

    static func saveToDownloadsFolder(
        filename: String,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Could not save \(data.count.formatted(.byteCount(style: .file))) CSV file \"\(filename)\" to the downloads folder.",
            underlyingErrors: [error],
            userInfo: ["filename": filename])
    }
}
