//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageCore
import Testing

final class URLBuilderTests {

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

    fileprivate static let stringValuePercentEncoded: String = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

    fileprivate static let uuidNil: UUID? = nil
    fileprivate static let uuidValue: UUID = .init()
    fileprivate static let uuidString: String = uuidValue.uuidString

    fileprivate static let dateNil: Date? = nil
    fileprivate static let dateValue: Date = .now
    fileprivate static let dateString: String = dateValue.formatted(.iso8601)

    fileprivate static let boolValue: Bool = [true, false].randomElement()!
    fileprivate static let boolString: String = .init(boolValue)

    fileprivate static let urlString = "\(scheme)://\(user):\(password)@\(host):\(port)/api/1/products"

    @Test("URLBuilder - Setting All Components")
    func urlBuilderSettingAllComponents() throws {
        let url = try URLBuilder()
            .settingScheme(to: Self.scheme)
            .settingHost(to: Self.host)
            .settingPort(to: Self.port)
            .settingUser(to: Self.user)
            .settingPassword(to: Self.password)
            .appendingPath("api/1")
            .appendingPath("products")
            .addingTestQueryItems()
            .build()

        validateURL(url)
    }

    @Test("URLBuilder - From Partial String")
    func urlBuilderFromPartialString() throws {
        let url = try URLBuilder(Self.urlString)
            .addingTestQueryItems()
            .build()

        validateURL(url)
    }

    @Test("URLBuilder - No Scheme")
    func urlBuilderNoScheme() throws {
        let invalidURLString = Self.urlString.replacingOccurrences(of: Self.scheme, with: "")
        #expect(throws: URLError.self) {
            try URLBuilder(invalidURLString)
        }
    }

    @Test("URLBuilder - Invalid Format")
    func urlBuilderInvalidForm() throws {
        let invalidURLString = Self.urlString.replacingOccurrences(of: "/", with: "|")
        #expect(throws: URLError.self) {
            try URLBuilder(invalidURLString)
        }
    }

    private func validateURL(_ url: URL) {

        // We just created a valid URL so URLComponents must decode it
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

private extension URLBuilder {
    
    func addingTestQueryItems() -> URLBuilder {
        var builder = self

        builder = builder
            .addingQueryItem(name: "int_nil", value: URLBuilderTests.intNil)
            .addingQueryItem(name: "int_value", value: URLBuilderTests.intValue)

        builder = builder
            .addingQueryItem(name: "double_nil", value: URLBuilderTests.doubleNil)
            .addingQueryItem(name: "double_value", value: URLBuilderTests.doubleValue)

        builder = builder
            .addingQueryItem(name: "decimal_nil", value: URLBuilderTests.decimalNil)
            .addingQueryItem(name: "decimal_value", value: URLBuilderTests.decimalValue)

        builder = builder
            .addingQueryItem(name: "string_nil", value: URLBuilderTests.stringNil)
            .addingQueryItem(name: "string_value", value: URLBuilderTests.stringValue)

        builder = builder
            .addingQueryItem(name: "uuid_nil", value: URLBuilderTests.uuidNil)
            .addingQueryItem(name: "uuid_value", value: URLBuilderTests.uuidValue)

        builder = builder
            .addingQueryItem(name: "date_nil", value: URLBuilderTests.dateNil)
            .addingQueryItem(name: "date_value", value: URLBuilderTests.dateValue)
            .addingQueryItem(name: "bool_value", value: URLBuilderTests.boolValue)

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
