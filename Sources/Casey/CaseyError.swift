//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct CaseyError: Yikes {

    // MARK: - Properties

    // MARK: Oops Conformance

    public let refcode: String?
    public let summary: String
    public let title: String?
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: - Lifecycle

    // MARK: Initializers

    init(
        summary: String? = nil,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        refcode: String? = nil,
    ) {
        self.refcode = refcode
        self.summary = summary ?? "Failed to save file."
        self.title = title ?? "CSV Error"
        self.details = details
        self.userInfo = userInfo
        self.underlyingError = underlyingError
    }

    // MARK: Factory Methods

    static func saveTo(
        _ url: URL,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Failed to save file.",
            details: "\(data.count.formatted(.byteCount(style: .file))) to \"\(url.lastPathComponent)\".",
            underlyingError: error,
            userInfo: ["url": url])
    }

    static func saveToDownloadsFolder(
        filename: String,
        data: Data,
        error: any Error,
    ) -> Self {

        .init(
            summary: "Failed to save \"\(filename)\" to Downloads.",
            details: "\(data.count.formatted(.byteCount(style: .file))).",
            underlyingError: error,
            userInfo: ["filename": filename])
    }
}
