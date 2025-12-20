//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public final class TextValidator: Validator {

    typealias CustomValidator = (String) -> Bool

    private var requirements = Set<Requirement>()
    private var customValidators = [String: CustomValidator]()

    // swiftlint:disable opening_brace
    private lazy var emailRegex = /\S+@\S+\.\S+/
    private lazy var phoneNumberRegex = /^\+?[0-9]{1,}$/
    private lazy var specialCharacterRegex =
        /[`~!@#$%^&*()_|+\-=?;:'",.<>\{\}\[\]\\\/]/
    // swiftlint:enable opening_brace

    func removeAllRequirements() {
        requirements.removeAll()
    }

    func addRequirement(_ requirement: Requirement) {
        requirements.update(with: requirement)
    }

    func removeRequirement(_ requirement: Requirement) {
        requirements.remove(requirement)
    }

    func addCustomValidator(id: String, validator: @escaping CustomValidator) {
        customValidators[id] = validator
    }

    func removeCustomValidator(id: String) {
        customValidators.removeValue(forKey: id)
    }

    public func validate(_ text: String) -> ValidationResult<String, Violation> {
        var violations = [Violation]()

        for requirement in requirements {
            switch requirement {
            case .notOnlyWhitespace:
                if text.isAllWhitespace {
                    violations.append(.onlyWhitespace)
                }

            case let .minLength(minLength):
                if text.count < minLength {
                    violations.append(.belowMinLength)
                }

            case let .maxLength(maxLength):
                if text.count > maxLength {
                    violations.append(.aboveMaxLength)
                }

            case .containsLowercaseCharacters:
                if text.rangeOfCharacter(from: .lowercaseLetters) == nil {
                    violations.append(.missingLowercaseCharacters)
                }

            case .containsUppercaseCharacters:
                if text.rangeOfCharacter(from: .uppercaseLetters) == nil {
                    violations.append(.missingUppercaseCharacters)
                }

            case .containsNumericCharacters:
                if text.rangeOfCharacter(from: .decimalDigits) == nil {
                    violations.append(.missingUppercaseCharacters)
                }

            case .containsSpecialCharacters:
                if text.firstMatch(of: specialCharacterRegex) == nil {
                    violations.append(.missingSpecialCharacters)
                }

            case .validEmail:
                if text.firstMatch(of: emailRegex) == nil {
                    violations.append(.invalidEmail)
                }

            case .validPhoneNumber:
                if text.firstMatch(of: phoneNumberRegex) == nil {
                    violations.append(.invalidPhoneNumber)
                }
            }
        }

        for (id, validator) in customValidators where !validator(text) {
            violations.append(.custom(id))
        }

        return ValidationResult(value: text, violations: violations)
    }

    public enum Requirement: Equatable, Hashable {
        case notOnlyWhitespace
        case minLength(Int)
        case maxLength(Int)
        case containsLowercaseCharacters
        case containsUppercaseCharacters
        case containsNumericCharacters
        case containsSpecialCharacters
        case validEmail
        case validPhoneNumber
    }

    public enum Violation: Equatable {
        case onlyWhitespace
        case belowMinLength
        case aboveMaxLength
        case missingLowercaseCharacters
        case missingUppercaseCharacters
        case missingNumericCharacters
        case missingSpecialCharacters
        case invalidEmail
        case invalidPhoneNumber
        case custom(String)
    }
}
