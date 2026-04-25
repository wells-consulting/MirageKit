//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JaysonError: MirageKitError {

    public enum Process: Sendable {
        case encode
        case decode
    }

    // MARK: - Properties

    // MARK: Yikes conformance

    public let refcode: String?
    public let summary: String
    public let title: String?
    public let details: String?
    public let underlyingError: (any Error)?
    public let userInfo: [String: any Sendable]?

    // MARK: JaysonError specific

    public let process: Process
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

    public init(
        process: Process,
        summary: String? = nil,
        title: String? = nil,
        details: String? = nil,
        underlyingError: (any Error)? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
        refcode: String? = nil,
    ) {

        self.title = title ?? (process == .encode ? "Encoding Error" : "Decoding Error")

        self.summary = summary ?? (process == .encode ? "Encoding failed." : "Decoding failed.")
        self.details = details

        self.underlyingError = underlyingError
        self.userInfo = userInfo

        self.process = process
        self.jsonText =
            if let data {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }

        self.refcode = refcode
    }

    public static func wrap(_ error: DecodingError, refcode: String? = nil) -> JaysonError? {

        let details: String

        var underlyingError: (any Error)?

        switch error {
        case let .dataCorrupted(context):
            underlyingError = context.underlyingError
            details = "Data corrupted\(context.atPathString)."
        case let .keyNotFound(key, context):
            underlyingError = context.underlyingError
            details = "Missing key \"\(key.stringValue)\"\(context.atPathString)."
        case let .valueNotFound(type, context):
            underlyingError = context.underlyingError
            details = "Missing \(type)\(context.atPathString)."
        case let .typeMismatch(type, context):
            underlyingError = context.underlyingError
            details = "Expected \(type)\(context.atPathString)."
        default:
            return nil
        }

        return JaysonError(
            process: .decode,
            summary: "The data could not be read.",
            details: details,
            underlyingError: underlyingError,
            refcode: refcode,
        )
    }
}
