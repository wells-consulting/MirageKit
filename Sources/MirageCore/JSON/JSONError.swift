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

    public let refcode: String?
    public let summary: String
    public let alertTitle: String?
    public let details: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: JSONError specific

    public let process: Process
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

    private init(
        process: Process,
        summary: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        jsonText: String? = nil,
        refcode: String? = nil,
    ) {
        self.process = process
        self.alertTitle = alertTitle
        self.summary = summary ?? "Could not complete JSON operation."
        self.details = details
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo
        self.jsonText = jsonText
        self.refcode = refcode
    }

    public init(
        process: Process,
        summary: String? = nil,
        alertTitle: String? = nil,
        details: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
        refcode: String? = nil,
    ) {

        self.alertTitle = alertTitle ?? "JSON Error"

        self.summary = summary ?? "Could not complete JSON operation."
        self.details = details

        self.underlyingErrors = underlyingErrors
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

    public static func wrap(_ error: DecodingError, refcode: String? = nil) -> JSONError? {

        let summary: String

        var underlyingError: (any Error)?

        switch error {
        case let .dataCorrupted(context):
            underlyingError = context.underlyingError
            summary = "Could not decode because the data is corrupted\(context.atPathString)."
        case let .keyNotFound(key, context):
            underlyingError = context.underlyingError
            summary = "Could not decode because key \"\(key.stringValue)\" is missing\(context.atPathString)."
        case let .valueNotFound(type, context):
            underlyingError = context.underlyingError
            summary = "Could not decode a \(type.self) because value not found\(context.atPathString)."
        case let .typeMismatch(type, context):
            underlyingError = context.underlyingError
            summary = "Could not decode because \(type) not found\(context.atPathString)."
        default:
            return nil
        }

        let underlyingErrors: [any Error]? =
            if let underlyingError {
                [underlyingError]
            } else {
                nil
            }

        return JSONError(
            process: .decode,
            summary: summary,
            alertTitle: "JSON Error (Wrapped)",
            underlyingErrors: underlyingErrors,
            userInfo: nil,
            data: nil,
            refcode: refcode,
        )
    }
}
