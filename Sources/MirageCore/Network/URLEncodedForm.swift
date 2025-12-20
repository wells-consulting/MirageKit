//
// Copyright 2025 Wells Consulting.
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
        let string = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        if let encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return Data(encodedString.utf8)
        } else {
            return Data(string.utf8)
        }
    }

    public func addingField(name: String, value: String) -> Self {
        parameters[name] = value
        return self
    }
}
