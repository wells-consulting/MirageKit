//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
import MirageCore

public final class DoubleValidator: Validator {

    typealias CustomValidator = (Double) -> Bool

    private let formatter: NumberFormatter
    private var requirements = Set<Requirement>()
    private var customValidators = [String: CustomValidator]()

    init(formatter: NumberFormatter) {
        self.formatter = formatter
    }

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

    public func validate(_ text: String) -> ValidationResult<Double, Violation> {
        let value = formatter.number(from: text)?.doubleValue

        var violations = [Violation]()

        if value == nil {
            violations.append(.invalidFormat)
        }

        for requirement in requirements {
            switch requirement {
            case .validFormat:
                break // Implicitly handled above

            case let .minValue(minValue):
                if let value, value < minValue {
                    violations.append(.belowMinValue)
                }

            case let .maxValue(maxValue):
                if let value, value > maxValue {
                    violations.append(.aboveMaxValue)
                }

            case let .maxFractionalDigits(maxFractionalDigits):
                let components = text.components(separatedBy: Locale.current.decimalSeparator ?? ".")
                if components.count == 2 {
                    let trailingDigits = components[1].removingTrailingInstances(of: "0")
                    if trailingDigits.count > maxFractionalDigits {
                        violations.append(.aboveMaxFractionalDigits)
                    }
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
        case minValue(Double)
        case maxValue(Double)
        case maxFractionalDigits(Int)
    }

    public enum Violation: Equatable {
        case invalidFormat
        case belowMinValue
        case aboveMaxValue
        case aboveMaxFractionalDigits
        case custom(String)
    }
}
