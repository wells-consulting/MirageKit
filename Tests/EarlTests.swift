//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Builder Tests

@Suite("Earl - Init")
struct EarlInitTests {

    @Test("From valid URL string")
    func fromValidString() throws {
        let earl = try Earl("https://example.com/api/v1")
        let url = try earl.build()
        #expect(url.scheme == "https")
        #expect(url.host() == "example.com")
        #expect(url.path() == "/api/v1")
    }

    @Test("From URL object")
    func fromURL() throws {
        let source = URL(string: "https://example.com/path")!
        let url = try Earl(source).build()
        #expect(url.absoluteString == "https://example.com/path")
    }

    @Test("Empty init requires scheme and host to build")
    func emptyInitNeedsSchemeAndHost() {
        #expect(throws: EarlError.self) {
            try Earl().build()
        }
    }

    @Test("Missing scheme throws EarlError")
    func missingScheme() {
        #expect(throws: EarlError.self) {
            try Earl("://example.com")
        }
    }

    @Test("Missing host throws EarlError")
    func missingHost() {
        // Opaque URIs like "custom:" have scheme but no host in URLComponents
        #expect(throws: EarlError.self) {
            try Earl("custom:")
        }
    }

    @Test("Unparseable string throws EarlError")
    func unparseableString() {
        #expect(throws: EarlError.self) {
            try Earl("not||a||url")
        }
    }

    @Test("Parses port from string")
    func parsesPort() throws {
        let url = try Earl("https://example.com:8080/api").build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.port == 8080)
    }

    @Test("Parses user and password from string")
    func parsesCredentials() throws {
        let url = try Earl("https://admin:secret@example.com/api").build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.user == "admin")
        #expect(components.password == "secret")
    }

    @Test("Parses existing query items from string")
    func parsesExistingQueryItems() throws {
        let url = try Earl("https://example.com/api?key=value").build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.queryItems?.first?.name == "key")
        #expect(components.queryItems?.first?.value == "value")
    }
}

@Suite("Earl - Base Components")
struct EarlBaseComponentTests {

    @Test("Set scheme")
    func setScheme() throws {
        let url = try Earl()
            .scheme( "https")
            .host( "example.com")
            .build()
        #expect(url.scheme == "https")
    }

    @Test("Set scheme nil is no-op")
    func setSchemeNil() throws {
        let url = try Earl("https://example.com")
            .scheme( nil)
            .build()
        #expect(url.scheme == "https")
    }

    @Test("Set host")
    func setHost() throws {
        let url = try Earl()
            .scheme( "https")
            .host( "api.example.com")
            .build()
        #expect(url.host() == "api.example.com")
    }

    @Test("Set host nil is no-op")
    func setHostNil() throws {
        let url = try Earl("https://example.com")
            .host( nil)
            .build()
        #expect(url.host() == "example.com")
    }

    @Test("Set port")
    func setPort() throws {
        let url = try Earl("https://example.com")
            .port( 9090)
            .build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.port == 9090)
    }

    @Test("Set port nil is no-op")
    func setPortNil() throws {
        let url = try Earl("https://example.com:8080")
            .port( nil)
            .build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.port == 8080)
    }

    @Test("Set user and password")
    func setUserAndPassword() throws {
        let url = try Earl("https://example.com")
            .user( "admin")
            .password( "pass123")
            .build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.user == "admin")
        #expect(components.password == "pass123")
    }

    @Test("Set user nil is no-op")
    func setUserNil() throws {
        let url = try Earl("https://admin:pass@example.com")
            .user( nil)
            .build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.user == "admin")
    }

    @Test("Set password nil is no-op")
    func setPasswordNil() throws {
        let url = try Earl("https://admin:pass@example.com")
            .password( nil)
            .build()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.password == "pass")
    }
}

@Suite("Earl - Path")
struct EarlPathTests {

    @Test("Append single path segment")
    func appendSingleSegment() throws {
        let url = try Earl("https://example.com")
            .path("api")
            .build()
        #expect(url.path() == "/api")
    }

    @Test("Append multi-segment path")
    func appendMultiSegment() throws {
        let url = try Earl("https://example.com")
            .path("api/v1/users")
            .build()
        #expect(url.path() == "/api/v1/users")
    }

    @Test("Append multiple paths sequentially")
    func appendSequential() throws {
        let url = try Earl("https://example.com")
            .path("api")
            .path("v1")
            .path("users")
            .build()
        #expect(url.path() == "/api/v1/users")
    }

    @Test("Append nil path is no-op")
    func appendNilPath() throws {
        let url = try Earl("https://example.com/api")
            .path(nil)
            .build()
        #expect(url.path() == "/api")
    }

    @Test("Append path to existing path from string")
    func appendToExistingPath() throws {
        let url = try Earl("https://example.com/api/v1")
            .path("users")
            .build()
        #expect(url.path() == "/api/v1/users")
    }
}

@Suite("Earl - Query Items")
struct EarlQueryItemTests {

    @Test("Bool query item true")
    func boolTrue() throws {
        let url = try Earl("https://example.com")
            .query( "active", true)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "true")
    }

    @Test("Bool query item false")
    func boolFalse() throws {
        let url = try Earl("https://example.com")
            .query( "active", false)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "false")
    }

    @Test("Int query item")
    func intValue() throws {
        let url = try Earl("https://example.com")
            .query( "page", 42)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "42")
    }

    @Test("Int nil query item is skipped")
    func intNil() throws {
        let url = try Earl("https://example.com")
            .query( "page", nil as Int?)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems
        #expect(qi == nil)
    }

    @Test("Int32 query item")
    func int32Value() throws {
        let url = try Earl("https://example.com")
            .query( "code", Int32(999))
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "999")
    }

    @Test("Int64 query item")
    func int64Value() throws {
        let url = try Earl("https://example.com")
            .query( "id", Int64(9_999_999_999))
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "9999999999")
    }

    @Test("Float query item")
    func floatValue() throws {
        let url = try Earl("https://example.com")
            .query( "ratio", Float(1.5))
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "1.5")
    }

    @Test("Double query item")
    func doubleValue() throws {
        let url = try Earl("https://example.com")
            .query( "pi", 3.14159)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "3.14159")
    }

    @Test("Decimal query item")
    func decimalValue() throws {
        let url = try Earl("https://example.com")
            .query( "price", Decimal(99.99))
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.name == "price")
        #expect(qi.first?.value != nil)
    }

    @Test("String query item")
    func stringValue() throws {
        let url = try Earl("https://example.com")
            .query( "name", "hello" as String?)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "hello")
    }

    @Test("String nil query item is skipped")
    func stringNil() throws {
        let url = try Earl("https://example.com")
            .query( "name", nil as String?)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems
        #expect(qi == nil)
    }

    @Test("UUID query item")
    func uuidValue() throws {
        let id = UUID()
        let url = try Earl("https://example.com")
            .query( "id", id)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == id.uuidString)
    }

    @Test("UUID nil query item is skipped")
    func uuidNil() throws {
        let url = try Earl("https://example.com")
            .query( "id", nil as UUID?)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems
        #expect(qi == nil)
    }

    @Test("Date query item uses ISO8601 by default")
    func dateISO8601() throws {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let url = try Earl("https://example.com")
            .query( "since", date)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == date.formatted(.iso8601))
    }

    @Test("Date nil query item is skipped")
    func dateNil() throws {
        let url = try Earl("https://example.com")
            .query( "since", nil as Date?)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems
        #expect(qi == nil)
    }

    @Test("Date with custom formatter")
    func dateCustomFormatter() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let date = Date(timeIntervalSince1970: 1_000_000)
        let url = try Earl("https://example.com")
            .query( "since", date, formatter: formatter)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "1970-01-12")
    }

    @Test("Date with override formatter from init")
    func dateOverrideFormatter() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let date = Date(timeIntervalSince1970: 1_000_000)
        let url = try Earl("https://example.com", dateFormatter: formatter)
            .query( "year", date)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.first?.value == "1970")
    }

    @Test("Multiple query items are preserved in order")
    func multipleQueryItems() throws {
        let url = try Earl("https://example.com")
            .query( "a", 1)
            .query( "b", 2)
            .query( "c", 3)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.count == 3)
        #expect(qi[0].name == "a")
        #expect(qi[1].name == "b")
        #expect(qi[2].name == "c")
    }

    @Test("Query items merge with existing from URL string")
    func mergeWithExisting() throws {
        let url = try Earl("https://example.com?existing=1")
            .query( "new", 2)
            .build()
        let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        #expect(qi.count == 2)
        #expect(qi.contains(where: { $0.name == "existing" && $0.value == "1" }))
        #expect(qi.contains(where: { $0.name == "new" && $0.value == "2" }))
    }
}

@Suite("Earl - absoluteString")
struct EarlAbsoluteStringTests {

    @Test("Full URL produces correct absoluteString")
    func fullAbsoluteString() throws {
        let earl = try Earl("https://example.com/api")
            .query( "key", "val")
        #expect(earl.absoluteString.contains("https://"))
        #expect(earl.absoluteString.contains("example.com"))
        #expect(earl.absoluteString.contains("/api"))
        #expect(earl.absoluteString.contains("key=val"))
    }

    @Test("Empty builder has empty absoluteString")
    func emptyAbsoluteString() {
        let earl = Earl()
        #expect(earl.absoluteString == "")
    }
}

@Suite("Earl - Build Errors")
struct EarlBuildErrorTests {

    @Test("Build without scheme throws")
    func buildNoScheme() {
        let earl = Earl().host( "example.com")
        #expect(throws: EarlError.self) {
            try earl.build()
        }
    }

    @Test("Build without host throws")
    func buildNoHost() {
        let earl = Earl().scheme( "https")
        #expect(throws: EarlError.self) {
            try earl.build()
        }
    }
}

// MARK: - URL Extension Tests

@Suite("URL - Earl Extensions")
struct URLExtensionTests {

    @Test("URL.from valid string")
    func urlFromValid() throws {
        let url = try URL.from("https://example.com")
        #expect(url.scheme == "https")
        #expect(url.host() == "example.com")
    }

    @Test("URL.from invalid string throws EarlError")
    func urlFromInvalid() {
        #expect(throws: EarlError.self) {
            try URL.from("")
        }
    }

    @Test("URL init with optional string")
    func urlInitOptionalString() {
        let url = URL(string: "https://example.com" as String?)
        #expect(url != nil)
    }

    @Test("URL init with nil string returns nil")
    func urlInitNilString() {
        let url = URL(string: nil as String?)
        #expect(url == nil)
    }
}

// MARK: - EarlError Tests

@Suite("EarlError")
struct EarlErrorTests {

    @Test("Default summary is 'Invalid URL.'")
    func defaultSummary() {
        let error = EarlError()
        #expect(error.summary == "Invalid URL.")
    }

    @Test("Default title is 'URL Error'")
    func defaultTitle() {
        let error = EarlError()
        #expect(error.title == "URL Error")
    }

    @Test("missingScheme has user-friendly summary and technical details")
    func missingSchemeMessage() {
        let error = EarlError.missingScheme(urlString: "://host", urlComponents: nil)
        #expect(error.summary == "Invalid URL.")
        #expect(error.details?.contains("Missing scheme") == true)
        #expect(error.details?.contains("://host") == true)
        #expect(error.urlString == "://host")
    }

    @Test("missingHost has user-friendly summary and technical details")
    func missingHostMessage() {
        let error = EarlError.missingHost(urlString: "https://", urlComponents: nil)
        #expect(error.summary == "Invalid URL.")
        #expect(error.details?.contains("Missing host") == true)
        #expect(error.details?.contains("https://") == true)
        #expect(error.urlString == "https://")
    }

    @Test("invalidURL has user-friendly summary and technical details")
    func invalidURLMessage() {
        let error = EarlError.invalidURL(urlString: "bad", urlComponents: nil)
        #expect(error.summary == "Invalid URL.")
        #expect(error.details?.contains("bad") == true)
        #expect(error.urlString == "bad")
    }

    @Test("urlComponents is preserved")
    func urlComponentsPreserved() {
        let components = URLComponents(string: "https://example.com")
        let error = EarlError.missingScheme(urlString: "test", urlComponents: components)
        #expect(error.urlComponents?.host == "example.com")
    }

    @Test("Conforms to Yikes")
    func conformsToYikes() {
        let error: any Yikes = EarlError()
        #expect(error.summary == "Invalid URL.")
    }
}

// MARK: - Integration Tests

@Suite("Earl - Integration")
struct EarlIntegrationTests {

    fileprivate static let scheme: String = ["http", "https", "file"].randomElement()!
    fileprivate static let host: String = "fleet-api.prd.na.vn.cloud.tesla.com"

    fileprivate static let port: Int = .random(in: 0 ..< 65536)
    fileprivate static let user: String = UUID().uuidString
    fileprivate static let password: String = UUID().uuidString

    fileprivate static let intNil: Int? = nil
    fileprivate static let intValue: Int = .random(in: 0 ..< 10000)
    fileprivate static let intString: String = .init(intValue)

    fileprivate static let doubleNil: Double? = nil
    fileprivate static let doubleValue: Double = .pi
    fileprivate static let doubleString: String = .init(doubleValue)

    fileprivate static let decimalNil: Decimal? = nil
    fileprivate static let decimalValue: Decimal = .init(doubleValue * Double(intValue))
    fileprivate static let decimalString: String = .init(describing: decimalValue)

    fileprivate static let stringNil: String? = nil
    fileprivate static let stringValue: String = {
        let characters = String(CharacterSet.urlQueryAllowed.inverted.characters())
        return String((0 ..< 20).map { _ in characters.randomElement()! })
    }()

    fileprivate static let uuidNil: UUID? = nil
    fileprivate static let uuidValue: UUID = .init()
    fileprivate static let uuidString: String = uuidValue.uuidString

    fileprivate static let dateNil: Date? = nil
    fileprivate static let dateValue: Date = .now
    fileprivate static let dateString: String = dateValue.formatted(.iso8601)

    fileprivate static let boolValue: Bool = [true, false].randomElement()!
    fileprivate static let boolString: String = .init(boolValue)

    fileprivate static let urlString = "\(scheme)://\(user):\(password)@\(host):\(port)/api/1/products"

    @Test("Setting all components builds correct URL")
    func settingAllComponents() throws {
        let url = try Earl()
            .scheme( Self.scheme)
            .host( Self.host)
            .port( Self.port)
            .user( Self.user)
            .password( Self.password)
            .path("api/1")
            .path("products")
            .addingTestQueryItems()
            .build()

        validateURL(url)
    }

    @Test("From partial string builds correct URL")
    func fromPartialString() throws {
        let url = try Earl(Self.urlString)
            .addingTestQueryItems()
            .build()

        validateURL(url)
    }

    private func validateURL(_ url: URL) {
        let components = URLComponents(string: url.absoluteString)!

        #expect(components.scheme == Self.scheme)
        #expect(components.host == Self.host)
        #expect(components.port == Self.port)
        #expect(components.user == Self.user)
        #expect(components.password == Self.password)
        #expect(components.path == "/api/1/products")

        let queryItems = components.queryItems!

        #expect(queryItems.count == 7)
        #expect(queryItems.contains(where: { $0.name == "int_value" && $0.value == Self.intString }))
        #expect(queryItems.contains(where: { $0.name == "double_value" && $0.value == Self.doubleString }))
        #expect(queryItems.contains(where: { $0.name == "decimal_value" && $0.value == Self.decimalString }))
        #expect(queryItems.contains(where: { $0.name == "string_value" && $0.value == Self.stringValue }))
        #expect(queryItems.contains(where: { $0.name == "uuid_value" && $0.value == Self.uuidString }))
        #expect(queryItems.contains(where: { $0.name == "date_value" && $0.value == Self.dateString }))
        #expect(queryItems.contains(where: { $0.name == "bool_value" && $0.value == Self.boolString }))
    }
}

private extension Earl {

    func addingTestQueryItems() -> Earl {
        var builder = self

        builder = builder
            .query( "int_nil", EarlIntegrationTests.intNil)
            .query( "int_value", EarlIntegrationTests.intValue)

        builder = builder
            .query( "double_nil", EarlIntegrationTests.doubleNil)
            .query( "double_value", EarlIntegrationTests.doubleValue)

        builder = builder
            .query( "decimal_nil", EarlIntegrationTests.decimalNil)
            .query( "decimal_value", EarlIntegrationTests.decimalValue)

        builder = builder
            .query( "string_nil", EarlIntegrationTests.stringNil)
            .query( "string_value", EarlIntegrationTests.stringValue)

        builder = builder
            .query( "uuid_nil", EarlIntegrationTests.uuidNil)
            .query( "uuid_value", EarlIntegrationTests.uuidValue)

        builder = builder
            .query( "date_nil", EarlIntegrationTests.dateNil)
            .query( "date_value", EarlIntegrationTests.dateValue)
            .query( "bool_value", EarlIntegrationTests.boolValue)

        return builder
    }
}

private extension CharacterSet {
    func characters() -> [Character] {
        codePoints().compactMap { UnicodeScalar($0) }.map { Character($0) }
    }

    func codePoints() -> [Int] {
        var result: [Int] = []
        var plane = 0
        // https://developer.apple.com/documentation/foundation/nscharacterset/1417719-bitmaprepresentation
        for (i, w) in bitmapRepresentation.enumerated() {
            let k = i % 0x2001
            if k == 0x2000 {
                // plane index byte
                plane = Int(w) << 13
                continue
            }
            let base = (plane + k) << 3
            for j in 0 ..< 8 where w & 1 << j != 0 {
                result.append(base + j)
            }
        }
        return result
    }
}
