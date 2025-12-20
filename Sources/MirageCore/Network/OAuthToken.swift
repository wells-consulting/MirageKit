//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct OAuthToken: Codable, CustomStringConvertible, Sendable {

    public let accessToken: String?
    public let createdAt: Date? = Date()
    public let expiresIn: TimeInterval?
    public let refreshToken: String?
    public let idToken: String?

    public var expiration: Date? {
        if let createdAt, let expiresIn {
            createdAt.addingTimeInterval(expiresIn)
        } else {
            nil
        }
    }

    public var isExpired: Bool {
        if let createdAt, let expiresIn {
            -createdAt.timeIntervalSinceNow > expiresIn
        } else {
            true
        }
    }

    public var description: String {
        if let createdAt, let expiresAt = expiration {
            if expiresAt < .now {
                let durationDescription = Date.debugDurationDescriptionString(from: expiresAt, to: .now)
                let text = "Created on \(createdAt.formatted(date: .abbreviated, time: .shortened)), expired on \(expiresAt.formatted(date: .abbreviated, time: .shortened)) (\(durationDescription))"
                return text
            } else {
                let durationDescription = Date.debugDurationDescriptionString(from: .now, to: expiresAt)
                let text = "Created on \(createdAt.formatted(date: .abbreviated, time: .shortened)), expires on \(expiresAt.formatted(date: .abbreviated, time: .shortened)) (\(durationDescription))"
                return text
            }
        } else if isExpired {
            if let expiration {
                return "Authorization token expired at \(expiration.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Authorization token expired."
            }
        } else {
            if let expiration {
                return "Authorization token valid until \(expiration.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Authorization token valid."
            }
        }
    }

    public init(accessToken: String?, idToken: String? = nil, refreshToken: String? = nil, expiration: Date? = nil) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiration?.timeIntervalSince1970
    }

    public init(accessToken: String?, idToken: String? = nil, refreshToken: String? = nil, expiration: TimeInterval? = nil) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.expiresIn = expiration
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }

    enum GrantType {
        case authorizationCode(String)
        case refreshToken(String)

        var name: String {
            switch self {
            case .authorizationCode:
                "authorization_code"
            case .refreshToken:
                "refresh_token"
            }
        }

        var key: String {
            switch self {
            case .authorizationCode:
                "code"
            case .refreshToken:
                "refresh_token"
            }
        }

        var value: String {
            switch self {
            case let .authorizationCode(code):
                code
            case let .refreshToken(token):
                token
            }
        }
    }
}
