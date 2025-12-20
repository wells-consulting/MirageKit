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
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recovery: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: JSONError specific

    public let process: Process
    public let jsonText: String?

    // MARK: - Lifecycle

    // MARK: Initializer

    private init(
        process: Process,
        refcode: String? = nil,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        jsonText: String? = nil,
    ) {
        self.process = process
        self.refcode = refcode
        self.alertTitle = alertTitle
        self.clarification = clarification
        self.details = details
        self.recovery = recovery
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo
        self.jsonText = jsonText
    }

    public init(
        process: Process,
        refcode: String? = nil,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recovery: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
    ) {

        self.refcode = refcode
        self.alertTitle = alertTitle ?? "Mirage JSON Error"

        // summary: "Error (Reference \(refcode))"
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

        self.recovery = recovery
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
}
