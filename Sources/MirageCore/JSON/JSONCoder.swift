//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JSONCoder: Sendable {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let log = Timber(subsystem: Bundle.appName, category: #fileID)

    public static let shared = JSONCoder()

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
    /// - Parameters
    ///     - value: Value to encode
    ///     - context: Additional coding context passed to encoders
    ///
    /// - Returns
    ///     - Raw encoded data
    ///
    /// - Throws
    ///     - JSONError if the value could not be encoded.
    public func encode<T: Encodable>(
        _ value: T,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String? = nil,
    ) throws -> Data {

        var summary = ""
        var underlyingError: (any Swift.Error)?

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
            summary = "Could not encode type \(T.self). The key \"\(key)\" is missing\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Could not encodf type \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JSONError(
            process: .encode,
            summary: summary,
            underlyingErrors: [underlyingError].compactMap(\.self),
            userInfo: errorUserInfo)
    }

    // MARK: - Decode

    /// Decode value from raw data.
    ///
    /// - Parameters
    ///     - data: Raw data
    ///     - context: Additional coding context passed to decoders
    ///
    /// - Returns
    ///     - Typed value
    ///
    /// - Throws
    ///     - JSONError if the value could not be decoded.
    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data?,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
    ) throws -> T {

        guard let data else {
            let message = "Could not decode \(T.self) because there is no data to decode."
            log.error(message)
            throw JSONError(process: .decode, summary: message)
        }

        var summary: String
        var underlyingError: (any Swift.Error)?

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
            summary = "Could not decode \(T.self) because the data is corrupted\(context.atPathString)."
        } catch let DecodingError.keyNotFound(key, context) {
            underlyingError = context.underlyingError
            summary = "Could not decode \(T.self) because key \"\(key.stringValue)\" is missing\(context.atPathString)."
        } catch let DecodingError.valueNotFound(type, context) {
            underlyingError = context.underlyingError
            summary = "Could not decode \(T.self) because value \(type) not found\(context.atPathString)."
        } catch let DecodingError.typeMismatch(type, context) {
            underlyingError = context.underlyingError
            summary = "Could not decode \(T.self) because \(type) not found\(context.atPathString)."
        } catch {
            underlyingError = error
            summary = "Could not decode \(T.self)."
        }

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JSONError(
            process: .decode,
            summary: summary,
            underlyingErrors: [underlyingError].compactMap(\.self),
            userInfo: errorUserInfo,
            data: data,
        )
    }

    // MARK: - Stringify

    /// Create JSON string from a value.
    ///
    /// - Parameters
    ///     - value: Value to convert
    ///
    /// - Returns
    ///     - JSON string if it can be created, nil otherwise
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
