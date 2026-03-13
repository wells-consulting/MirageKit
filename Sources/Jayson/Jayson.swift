//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct Jayson: Sendable {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let log = Timber(subsystem: Bundle.appName, category: #fileID)

    public static let shared = Jayson()

    // MARK: - Initializers

    public struct Configuration: Sendable {

        public let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
        public let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy
        public let outputFormatting: JSONEncoder.OutputFormatting

        public let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
        public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
        public let allowsJSON5: Bool

        public init(
            keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
            dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
            outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes],
            keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
            allowsJSON5: Bool = true,
        ) {
            self.keyEncodingStrategy = keyEncodingStrategy
            self.dateEncodingStrategy = dateEncodingStrategy
            self.outputFormatting = outputFormatting
            self.keyDecodingStrategy = keyDecodingStrategy
            self.dateDecodingStrategy = dateDecodingStrategy
            self.allowsJSON5 = allowsJSON5
        }

        public static let `default` = Configuration()
    }

    public init(configuration: Configuration = .default) {

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = configuration.keyEncodingStrategy
        encoder.dateEncodingStrategy = configuration.dateEncodingStrategy
        encoder.outputFormatting = configuration.outputFormatting
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = configuration.dateDecodingStrategy
        decoder.allowsJSON5 = configuration.allowsJSON5
        self.decoder = decoder
    }

    // MARK: - Encode

    /// Encode value to raw data.
    ///
    /// - Parameters:
    ///     - value: Value to encode.
    ///     - userInfo: Additional coding context passed to the encoder.
    ///     - refcode: Optional reference code attached to any thrown error.
    ///
    /// - Returns: Raw encoded data.
    ///
    /// - Throws: `JaysonError` if the value could not be encoded.
    public func encode<T: Encodable>(
        _ value: T,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String? = nil,
    ) throws -> Data {

        var summary = ""
        var underlyingError: (any Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    encoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        encoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            return try encoder.encode(value)
        } catch let EncodingError.invalidValue(key, context) {
            underlyingError = context.underlyingError
            summary = "Failed to encode \(T.self): key \"\(key)\" is missing\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Failed to encode \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JaysonError(
            process: .encode,
            summary: summary,
            underlyingError: underlyingError,
            userInfo: errorUserInfo,
            refcode: refcode)
    }

    // MARK: - Decode

    /// Decode value from raw data.
    ///
    /// - Parameters:
    ///     - type: The type to decode.
    ///     - data: Raw data, or `nil` which produces an error.
    ///     - userInfo: Additional coding context passed to the decoder.
    ///     - refcode: Optional reference code attached to any thrown error.
    ///
    /// - Returns: The decoded value.
    ///
    /// - Throws: `JaysonError` if the data is nil or cannot be decoded.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data?,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String? = nil,
    ) throws -> T {

        guard let data else {
            let message = "Failed to decode \(T.self): no data."
            log.error(message)
            throw JaysonError(process: .decode, summary: message, refcode: refcode)
        }

        var summary: String
        var underlyingError: (any Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    decoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        decoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            let object: T = try decoder.decode(T.self, from: data)

            return object
        } catch let DecodingError.dataCorrupted(context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): data corrupted\(context.atPathString)."
        } catch let DecodingError.keyNotFound(key, context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): missing key \"\(key.stringValue)\"\(context.atPathString)."
        } catch let DecodingError.valueNotFound(type, context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): missing \(type)\(context.atPathString)."
        } catch let DecodingError.typeMismatch(type, context) {
            underlyingError = context.underlyingError
            summary = "Failed to decode \(T.self): expected \(type)\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Failed to decode \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JaysonError(
            process: .decode,
            summary: summary,
            underlyingError: underlyingError,
            userInfo: errorUserInfo,
            data: data,
            refcode: refcode,
        )
    }

    // MARK: - Decode from String

    /// Decode value from a JSON string.
    ///
    /// - Parameters:
    ///     - type: The type to decode.
    ///     - string: A JSON string.
    ///     - userInfo: Additional coding context passed to the decoder.
    ///     - refcode: Optional reference code attached to any thrown error.
    ///
    /// - Returns: The decoded value.
    ///
    /// - Throws: `JaysonError` if the string cannot be decoded.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from string: String,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String? = nil,
    ) throws -> T {
        try decode(type, from: string.data(using: .utf8), userInfo: userInfo, refcode: refcode)
    }

    // MARK: - Encode to String

    /// Encode value to a JSON string.
    ///
    /// - Parameters:
    ///     - value: Value to encode.
    ///     - userInfo: Additional coding context passed to the encoder.
    ///     - refcode: Optional reference code attached to any thrown error.
    ///
    /// - Returns: A JSON string representation of the value.
    ///
    /// - Throws: `JaysonError` if the value could not be encoded.
    public func string<T: Encodable>(
        from value: T,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String? = nil,
    ) throws -> String {

        let data = try encode(value, userInfo: userInfo, refcode: refcode)

        guard let string = String(data: data, encoding: .utf8) else {
            throw JaysonError(
                process: .encode,
                summary: "Failed to encode \(T.self) to a UTF-8 string.",
                refcode: refcode,
            )
        }

        return string
    }

    // MARK: - Stringify

    /// Create JSON string from a value, returning `nil` on failure.
    ///
    /// For a throwing variant, use ``string(from:userInfo:refcode:)``.
    ///
    /// - Parameters:
    ///     - value: Value to convert.
    ///
    /// - Returns: A JSON string, or `nil` if encoding fails.
    public func stringify(_ value: some Encodable) -> String? {
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - Private Extensions

extension EncodingError.Context {

    var atPathString: String {

        let path = codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at \"\(path)\""
        }
    }
}

extension DecodingError.Context {

    var atPathString: String {

        let path = codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at \"\(path)\""
        }
    }
}
