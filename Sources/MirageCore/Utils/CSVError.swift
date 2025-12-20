//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct CSVError: MirageError {

    // MARK: - Properties

    // MARK: MirageError Conformance

    public let refcode: String?
    public let clarification: String?
    public let alertTitle: String?
    public let details: String?
    public let recovery: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        refcode: String? = nil,
        clarification: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode

        // summary: "Error (Reference \(refcode))"
        self.clarification = clarification ?? "Couldn't save CSV file."
        
        self.alertTitle = alertTitle ?? "Mirage CSV Error"
        self.details = details
        self.recovery = recovery
        self.userInfo = userInfo
        self.underlyingErrors = underlyingErrors
    }

    // MARK: Factory Methods

    static func saveTo(
        _ url: URL,
        data: Data,
        error: any Error,
        refcode: String
    ) -> Self {

        .init(
            refcode: refcode,
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file to '\(url.absoluteString)'.",
            underlyingErrors: [error],
            userInfo: ["url": url])
    }

    static func saveToDownloadsFolder(
        filename: String,
        data: Data,
        error: any Error,
        refcode: String
    ) -> Self {

        .init(
            refcode: refcode,
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file '\(filename)' to the downloads folder.",
            underlyingErrors: [error],
            userInfo: ["filename": filename])
    }
}
