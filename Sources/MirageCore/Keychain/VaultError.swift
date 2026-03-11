//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(Security)

import Foundation

public struct VaultError: MirageError {

    // MARK: - Properties

    // MARK: MirageError conformance

    public let refcode: String?
    public let summary: String
    public let title: String?
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: KeychainError specific

    /// The `OSStatus` returned by the Security framework, if applicable.
    public let status: OSStatus?

    // MARK: - Lifecycle

    // MARK: Initializer

    init(
        summary: String,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        status: OSStatus? = nil,
        refcode: String? = nil,
    ) {
        self.refcode = refcode
        self.summary = summary
        self.title = title ?? "Keychain Error"
        self.details = details
        self.underlyingError = underlyingError
        self.userInfo = userInfo
        self.status = status
    }

    // MARK: Factory Methods

    static func itemNotFound(key: String) -> VaultError {
        VaultError(
            summary: "No item found for key \"\(key)\".",
            status: errSecItemNotFound,
            refcode: "AXF9",
        )
    }

    static func saveFailed(key: String, status: OSStatus) -> VaultError {
        VaultError(
            summary: "Could not save item for key \"\(key)\" (OSStatus \(status)).",
            status: status,
            refcode: "4FJC",
        )
    }

    static func loadFailed(key: String, status: OSStatus) -> VaultError {
        VaultError(
            summary: "Could not load item for key \"\(key)\" (OSStatus \(status)).",
            status: status,
            refcode: "4T85",
        )
    }

    static func deleteFailed(key: String, status: OSStatus) -> VaultError {
        VaultError(
            summary: "Could not delete item for key \"\(key)\" (OSStatus \(status)).",
            status: status,
            refcode: "9UUD",
        )
    }

    static func encodingFailed(key: String, underlyingError: any Error) -> VaultError {
        VaultError(
            summary: "Could not encode item for key \"\(key)\".",
            underlyingError: underlyingError,
            refcode: "WWKF",
        )
    }

    static func decodingFailed(key: String, underlyingError: any Error) -> VaultError {
        VaultError(
            summary: "Could not decode item for key \"\(key)\".",
            underlyingError: underlyingError,
            refcode: "WWKF",
        )
    }
}

#endif
