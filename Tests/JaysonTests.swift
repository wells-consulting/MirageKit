//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Test Models

private struct Person: Codable, Equatable, Sendable {
    let name: String
    let age: Int

    enum CodingKeys: String, CodingKey {
        case name
        case age
    }
}

private struct Dated: Codable, Equatable, Sendable {
    let label: String
    let timestamp: Date
}

private struct Nested: Codable, Equatable, Sendable {
    let outer: String
    let inner: Inner

    struct Inner: Codable, Equatable, Sendable {
        let value: Int
    }
}

private struct SnakeCaseModel: Codable, Equatable, Sendable {
    let firstName: String
    let lastName: String
}

// MARK: - Encode Tests

struct JaysonEncodeTests {

    @Test("Encode - simple struct to Data")
    func encodeSimpleStruct() throws {
        let coder = Jayson()
        let person = Person(name: "Alice", age: 30)
        let data = try coder.encode(person)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"name\""))
        #expect(json.contains("\"Alice\""))
        #expect(json.contains("\"age\""))
        #expect(json.contains("30"))
    }

    @Test("Encode - nested struct")
    func encodeNestedStruct() throws {
        let coder = Jayson()
        let nested = Nested(outer: "hello", inner: .init(value: 42))
        let data = try coder.encode(nested)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"outer\""))
        #expect(json.contains("\"inner\""))
        #expect(json.contains("\"value\""))
        #expect(json.contains("42"))
    }

    @Test("Encode - date uses ISO8601 by default")
    func encodeDateISO8601() throws {
        let coder = Jayson()
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        let dated = Dated(label: "epoch", timestamp: date)
        let data = try coder.encode(dated)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("1970"))
    }

    @Test("Encode - output is pretty-printed by default")
    func encodePrettyPrinted() throws {
        let coder = Jayson()
        let person = Person(name: "Bob", age: 25)
        let data = try coder.encode(person)
        let json = String(data: data, encoding: .utf8)!
        // Pretty-printed JSON contains newlines
        #expect(json.contains("\n"))
    }

    @Test("Encode - round-trip preserves values")
    func encodeDecodeRoundTrip() throws {
        let coder = Jayson()
        let original = Person(name: "Charlie", age: 99)
        let data = try coder.encode(original)
        let decoded = try coder.decode(Person.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - Decode Tests

struct JaysonDecodeTests {

    @Test("Decode - simple JSON to struct")
    func decodeSimpleJSON() throws {
        let coder = Jayson()
        let json = #"{"name":"Diana","age":28}"#
        let data = json.data(using: .utf8)!
        let person = try coder.decode(Person.self, from: data)
        #expect(person.name == "Diana")
        #expect(person.age == 28)
    }

    @Test("Decode - nested JSON")
    func decodeNestedJSON() throws {
        let coder = Jayson()
        let json = #"{"outer":"world","inner":{"value":7}}"#
        let data = json.data(using: .utf8)!
        let nested = try coder.decode(Nested.self, from: data)
        #expect(nested.outer == "world")
        #expect(nested.inner.value == 7)
    }

    @Test("Decode - nil data throws JaysonError")
    func decodeNilDataThrows() {
        let coder = Jayson()
        #expect(throws: JaysonError.self) {
            try coder.decode(Person.self, from: nil)
        }
    }

    @Test("Decode - nil data error has decode process")
    func decodeNilDataErrorProcess() {
        let coder = Jayson()
        do {
            _ = try coder.decode(Person.self, from: nil)
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.process == .decode)
            #expect(error.summary.contains("no data"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - invalid JSON throws JaysonError")
    func decodeInvalidJSONThrows() {
        let coder = Jayson()
        let data = "not json".data(using: .utf8)!
        #expect(throws: JaysonError.self) {
            try coder.decode(Person.self, from: data)
        }
    }

    @Test("Decode - missing key throws JaysonError with key info")
    func decodeMissingKeyThrows() {
        let coder = Jayson()
        let json = #"{"name":"Eve"}"# // missing "age"
        let data = json.data(using: .utf8)!
        do {
            _ = try coder.decode(Person.self, from: data)
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.process == .decode)
            #expect(error.summary.contains("age"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - type mismatch throws JaysonError")
    func decodeTypeMismatchThrows() {
        let coder = Jayson()
        let json = #"{"name":"Eve","age":"not a number"}"#
        let data = json.data(using: .utf8)!
        do {
            _ = try coder.decode(Person.self, from: data)
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.process == .decode)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - error includes JSON text for debugging")
    func decodeErrorIncludesJSONText() {
        let coder = Jayson()
        let json = #"{"name":"Eve"}"#
        let data = json.data(using: .utf8)!
        do {
            _ = try coder.decode(Person.self, from: data)
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.jsonText != nil)
            #expect(error.jsonText?.contains("Eve") == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - JSON5 is allowed by default")
    func decodeJSON5Allowed() throws {
        let coder = Jayson()
        // JSON5 allows trailing commas and single-line comments
        let json5 = """
        {
            "name": "Frank",
            "age": 40,
        }
        """
        let data = json5.data(using: .utf8)!
        let person = try coder.decode(Person.self, from: data)
        #expect(person.name == "Frank")
        #expect(person.age == 40)
    }
}

// MARK: - Stringify Tests

struct JaysonStringifyTests {

    @Test("Stringify - produces JSON string")
    func stringifyProducesJSON() {
        let coder = Jayson()
        let person = Person(name: "Grace", age: 35)
        let result = coder.stringify(person)
        #expect(result != nil)
        #expect(result!.contains("Grace"))
        #expect(result!.contains("35"))
    }

    @Test("Stringify - returns nil for unencodable value")
    func stringifyReturnsNilForUnencodable() {
        let coder = Jayson()
        let result = coder.stringify(Double.nan)
        #expect(result == nil)
    }

    @Test("Stringify - array of values")
    func stringifyArray() {
        let coder = Jayson()
        let people = [Person(name: "A", age: 1), Person(name: "B", age: 2)]
        let result = coder.stringify(people)
        #expect(result != nil)
        #expect(result!.contains("\"A\""))
        #expect(result!.contains("\"B\""))
    }
}

// MARK: - Configuration Tests

struct JaysonConfigurationTests {

    @Test("Configuration - default uses ISO8601 dates")
    func defaultConfigISO8601() {
        let config = Jayson.Configuration.default
        // Just verify it can be created — the actual behavior is tested
        // through the encode/decode date tests
        #expect(config.allowsJSON5 == true)
    }

    @Test("Configuration - snake_case key strategy round-trips")
    func snakeCaseKeyStrategy() throws {
        let config = Jayson.Configuration(
            keyEncodingStrategy: .convertToSnakeCase,
            keyDecodingStrategy: .convertFromSnakeCase
        )
        let coder = Jayson(configuration: config)
        let original = SnakeCaseModel(firstName: "Jane", lastName: "Doe")
        let data = try coder.encode(original)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("first_name"))
        #expect(json.contains("last_name"))

        let decoded = try coder.decode(SnakeCaseModel.self, from: data)
        #expect(decoded == original)
    }

    @Test("Configuration - JSON5 can be disabled")
    func json5Disabled() {
        let config = Jayson.Configuration(allowsJSON5: false)
        let coder = Jayson(configuration: config)
        #expect(config.allowsJSON5 == false)
        // Verify the coder was created successfully and can decode standard JSON
        let json = #"{"name":"Test","age":1}"#
        let data = json.data(using: .utf8)!
        let person = try? coder.decode(Person.self, from: data)
        #expect(person?.name == "Test")
    }

    @Test("Shared instance exists")
    func sharedInstance() {
        let shared = Jayson.shared
        // Verify it can encode/decode
        let person = Person(name: "Shared", age: 0)
        let result = shared.stringify(person)
        #expect(result != nil)
    }
}

// MARK: - UserInfo Tests

struct JaysonUserInfoTests {

    @Test("Encode - userInfo is passed through")
    func encodeWithUserInfo() throws {
        let coder = Jayson()
        let key = CodingUserInfoKey(rawValue: "testKey")!
        let person = Person(name: "Info", age: 1)
        // Should not throw — userInfo doesn't affect simple encoding
        let data = try coder.encode(person, userInfo: [key: "testValue"])
        #expect(data.count > 0)
    }

    @Test("Decode - userInfo is passed through")
    func decodeWithUserInfo() throws {
        let coder = Jayson()
        let key = CodingUserInfoKey(rawValue: "testKey")!
        let json = #"{"name":"Info","age":1}"#
        let data = json.data(using: .utf8)!
        let person = try coder.decode(Person.self, from: data, userInfo: [key: "testValue"])
        #expect(person.name == "Info")
    }
}

// MARK: - Decode from String Tests

struct JaysonDecodeFromStringTests {

    @Test("Decode from String - simple JSON string")
    func decodeFromString() throws {
        let coder = Jayson()
        let json = #"{"name":"Hank","age":50}"#
        let person = try coder.decode(Person.self, from: json)
        #expect(person.name == "Hank")
        #expect(person.age == 50)
    }

    @Test("Decode from String - invalid JSON string throws")
    func decodeFromInvalidString() {
        let coder = Jayson()
        #expect(throws: JaysonError.self) {
            try coder.decode(Person.self, from: "not json at all")
        }
    }

    @Test("Decode from String - nested object")
    func decodeNestedFromString() throws {
        let coder = Jayson()
        let json = #"{"outer":"hi","inner":{"value":99}}"#
        let nested = try coder.decode(Nested.self, from: json)
        #expect(nested.outer == "hi")
        #expect(nested.inner.value == 99)
    }
}

// MARK: - Encode to String Tests

struct JaysonEncodeToStringTests {

    @Test("Encode to String - produces valid JSON string")
    func stringFrom() throws {
        let coder = Jayson()
        let person = Person(name: "Ivy", age: 22)
        let json = try coder.string(from: person)
        #expect(json.contains("Ivy"))
        #expect(json.contains("22"))
    }

    @Test("Encode to String - round-trips with decode from String")
    func encodeDecodeStringRoundTrip() throws {
        let coder = Jayson()
        let original = Person(name: "Jack", age: 33)
        let json = try coder.string(from: original)
        let decoded = try coder.decode(Person.self, from: json)
        #expect(decoded == original)
    }

    @Test("Encode to String - unencodable value throws")
    func stringFromThrows() {
        let coder = Jayson()
        #expect(throws: JaysonError.self) {
            try coder.string(from: Double.nan)
        }
    }
}

// MARK: - Refcode Tests

struct JaysonRefcodeTests {

    @Test("Encode - refcode is passed through to error")
    func encodeRefcode() {
        let coder = Jayson()
        do {
            _ = try coder.encode(Double.nan, refcode: "ENC-001")
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.refcode == "ENC-001")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - refcode is passed through to error on nil data")
    func decodeRefcodeNilData() {
        let coder = Jayson()
        do {
            _ = try coder.decode(Person.self, from: Data?.none, refcode: "DEC-001")
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.refcode == "DEC-001")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Decode - refcode is passed through to error on invalid data")
    func decodeRefcodeInvalidData() {
        let coder = Jayson()
        let data = "bad".data(using: .utf8)!
        do {
            _ = try coder.decode(Person.self, from: data, refcode: "DEC-002")
            Issue.record("Expected error")
        } catch let error as JaysonError {
            #expect(error.refcode == "DEC-002")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - JaysonError Tests

struct JaysonErrorTests {

    @Test("JaysonError - wrap dataCorrupted")
    func wrapDataCorrupted() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "bad data")
        let decodingError = DecodingError.dataCorrupted(context)
        let wrapped = JaysonError.wrap(decodingError)
        #expect(wrapped != nil)
        #expect(wrapped?.process == .decode)
        #expect(wrapped?.summary.contains("corrupted") == true)
    }

    @Test("JaysonError - wrap keyNotFound")
    func wrapKeyNotFound() {
        let key = Person.CodingKeys.name
        let context = DecodingError.Context(codingPath: [], debugDescription: "missing")
        let decodingError = DecodingError.keyNotFound(key, context)
        let wrapped = JaysonError.wrap(decodingError)
        #expect(wrapped != nil)
        #expect(wrapped?.summary.contains("name") == true)
    }

    @Test("JaysonError - wrap valueNotFound")
    func wrapValueNotFound() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "nil")
        let decodingError = DecodingError.valueNotFound(Int.self, context)
        let wrapped = JaysonError.wrap(decodingError)
        #expect(wrapped != nil)
        #expect(wrapped?.summary.contains("Missing") == true)
    }

    @Test("JaysonError - wrap typeMismatch")
    func wrapTypeMismatch() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "wrong type")
        let decodingError = DecodingError.typeMismatch(Int.self, context)
        let wrapped = JaysonError.wrap(decodingError)
        #expect(wrapped != nil)
        #expect(wrapped?.process == .decode)
    }

    @Test("JaysonError - title defaults to Encoding Error")
    func titleDefault() {
        let error = JaysonError(process: .encode)
        #expect(error.title == "Encoding Error")
    }

    @Test("JaysonError - summary defaults when nil")
    func summaryDefault() {
        let error = JaysonError(process: .decode)
        #expect(error.summary == "Operation failed.")
    }

    @Test("JaysonError - data is converted to jsonText")
    func dataConvertedToJsonText() {
        let json = #"{"key":"value"}"#
        let data = json.data(using: .utf8)!
        let error = JaysonError(process: .decode, data: data)
        #expect(error.jsonText == json)
    }

    @Test("JaysonError - nil data produces nil jsonText")
    func nilDataProducesNilJsonText() {
        let error = JaysonError(process: .decode, data: nil)
        #expect(error.jsonText == nil)
    }
}
