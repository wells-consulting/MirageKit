//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct ValidationResult<Value, Violation> {
    let value: Value?
    let violations: [Violation]
}

public protocol Validator {
    associatedtype Value
    associatedtype Violation

    func validate(_ text: String) -> ValidationResult<Value, Violation>
}
