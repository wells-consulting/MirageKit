//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public final class URLEncodedForm: SummaryProviding {

    private var parameters: [String: String] = [:]

    public var isEmpty: Bool { parameters.isEmpty }

    public var summary: String {
        parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }

    public init() {}

    public var data: Data {
        var components = URLComponents()
        components.queryItems = parameters.map {
            URLQueryItem(name: "\($0.key)", value: "\($0.value)")
        }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    public func addingField(name: String, value: String) -> Self {
        parameters[name] = value
        return self
    }
}
