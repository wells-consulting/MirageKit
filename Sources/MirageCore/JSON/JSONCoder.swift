//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JSONCoder: Sendable {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let log = Log(subsystem: Bundle.appName, category: #fileID)

    public static let shared = JSONCoder()

    // MARK: - Initializers

    public struct Configuration: Sendable {

        let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
        let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
        let outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
        let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
        let allowsJSON5: Bool = true

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
        refcode: String? = nil
    ) throws -> Data {

        var details = ""
        var clarification: String?
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
            clarification = context.debugDescription
            details = "A value of type '\(T.self)' could not be encoded. The key '\(key)' is missing\(context.atPathString)."
        } catch {
            underlyingError = error
            details = "A value of type '\(T.self)' could not be encoded.\n\(error)"
        }

        log.error(details)

        let errorUserInfo: [String: any Sendable]? = if let userInfo {
            Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
        } else {
            nil
        }

        throw JSONError(
            process: .encode,
            refcode: refcode,
            clarification: clarification ?? "JSON encode failed.",
            details: details,
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
        refcode: String? = nil
    ) throws -> T {

        guard let data else {

            let details = "\(T.self) could not be created because there is no data to decode."

            log.error(details)

            throw JSONError(
                process: .decode,
                refcode: refcode,
                clarification: "JSON decode failed.",
                details: details)
        }

        var details: String
        var clarification: String?
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
            clarification = context.debugDescription
            details = "A value of type '\(T.self)' could not be created because the data is corrupted\(context.atPathString) (DataCorrupted)."
        } catch let DecodingError.keyNotFound(key, context) {
            underlyingError = context.underlyingError
            clarification = context.debugDescription
            details = "A value of type '\(T.self)' could not be created because key '\(key.stringValue)' is missing\(context.atPathString) (KeyNotFound)."
        } catch let DecodingError.valueNotFound(type, context) {
            underlyingError = context.underlyingError
            clarification = context.debugDescription
            details = "A value of type '\(T.self)' could not be created because value \(type) not found\(context.atPathString) (ValueNotFound)."
        } catch let DecodingError.typeMismatch(type, context) {
            underlyingError = context.underlyingError
            clarification = context.debugDescription
            details = "A value of type '\(T.self)' could not be created because \(type) not found\(context.atPathString) (TypeMismatch)."
        } catch {
            underlyingError = error
            details = "A value of type '\(T.self)' could not be created.\n\(error.localizedDescription)"
        }

        log.error(details)

        let errorUserInfo: [String: any Sendable]? =
            if let userInfo {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
            } else {
                nil
            }

        throw JSONError(
            process: .decode,
            refcode: refcode,
            clarification: clarification ?? "JSON decode failed.",
            details: details,
            underlyingErrors: [underlyingError].compactMap(\.self),
            userInfo: errorUserInfo,
            data: data)
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

private extension EncodingError.Context {

    var atPathString: String {

        let path = codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at '\(path)'"
        }
    }
}

private extension DecodingError.Context {

    var atPathString: String {

        let path = codingPath
            .filter { !$0.stringValue.isEmpty }
            .map(\.stringValue)
            .joined(separator: ".")

        if path.isEmpty {
            return ""
        } else {
            return " at '\(path)'"
        }
    }
}
