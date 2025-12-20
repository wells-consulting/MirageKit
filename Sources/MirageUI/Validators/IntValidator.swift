//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
import MirageCore

public final class IntValidator: Validator {

    typealias CustomValidator = (Int) -> Bool

    private var requirements = Set<Requirement>()
    private var customValidators = [String: CustomValidator]()

    func removeAllRequirements() {
        requirements.removeAll()
    }

    func addRequirement(_ requirement: Requirement) throws {
        if case .validFormat = requirement { return }
        requirements.update(with: requirement)
    }

    func removeRequirement(_ requirement: Requirement) throws {
        if case .validFormat = requirement { return }
        requirements.remove(requirement)
    }

    func addCustomValidator(id: String, validator: @escaping CustomValidator) {
        customValidators[id] = validator
    }

    func removeCustomValidator(id: String) {
        customValidators.removeValue(forKey: id)
    }

    public func validate(_ text: String) -> ValidationResult<Int, Violation> {
        var violations = [Violation]()

        let value = text.intValue

        if value == nil {
            violations.append(.invalidFormat)
        }

        for requirement in requirements {
            switch requirement {
            case .validFormat:
                break // Implicitly handled above

            case let .aboveMinValue(minValue):
                if let value, value < minValue {
                    violations.append(.belowMinValue)
                }

            case let .belowMaxValue(maxValue):
                if let value, value > maxValue {
                    violations.append(.aboveMaxValue)
                }
            }
        }

        if let value {
            for (id, validator) in customValidators where !validator(value) {
                violations.append(.custom(id))
            }
        }

        return ValidationResult(value: value, violations: violations)
    }

    public enum Requirement: Equatable, Hashable {
        case validFormat
        case aboveMinValue(Int)
        case belowMaxValue(Int)
    }

    public enum Violation: Equatable {
        case invalidFormat
        case belowMinValue
        case aboveMaxValue
        case custom(String)
    }
}
