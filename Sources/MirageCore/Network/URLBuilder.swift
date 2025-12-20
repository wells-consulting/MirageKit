//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// An ergonomic builder to create URLs.
///
/// ```swift
/// let optionalInt: Int? = nil
/// let nonOptionalInt: Int = 333
///
/// // http://myhost.com/api/v1/date?from=333&isActive=true
/// let url = try URLBuilder("http://myhost.com/api/v1")
///     .appendingPath("date")
///     .addingQueryItem("date", optionalDate)
///     .addingQueryItem("from", nonOptionalInt)
///     .addingQueryItem("to", optionalInt)
///     .addingQueryItem("isActive", true)
///     .build()```
public final class URLBuilder {

    // MARK: - Fields

    private let refcode: String?
    private var scheme: String?
    private var host: String?
    private var port: Int?
    private var user: String?
    private var password: String?

    private var pathSegments: [String]
    private var queryItems: [URLQueryItem] = []
    private let overrideDateFormatter: DateFormatter?

    // MARK: - Computed Properties

    public var absoluteString: String {
        
        var absoluteString = if let scheme { "\(scheme)://" } else { "" }

        if let host {
            absoluteString.append("\(host)")
        }

        if let port { absoluteString.append(":\(port)/") }
        if let user, let password { absoluteString.append("\(user):\(password)") }

        if !pathSegments.isEmpty {
            absoluteString.append("/" + pathSegments.joined(separator: "/"))
        }

        if !queryItems.isEmpty {
            absoluteString.append("?")
            absoluteString.append(queryItems.map { "\($0.name)=\($0.value ?? "null")" }.joined(separator: "&"))
        }

        return absoluteString
    }

    // MARK: - Initializerss

    /// Initialize an empty builder.
    ///
    /// - Returns:
    ///     - Initialized URLBuilder
    public init(
        dateFormatter: DateFormatter? = nil,
        refcode: String? = nil
    ) {
        self.refcode = refcode
        self.scheme = nil
        self.host = nil
        self.port = nil
        self.user = nil
        self.password = nil
        self.pathSegments = []
        self.queryItems = []
        self.overrideDateFormatter = dateFormatter
    }

    /// Initialize a builder from a string.
    ///
    /// - Parameters:
    ///     - string: A valid URL string that includes, at a minimum, a scheme and host.
    ///     For example, "http://host" is sufficient. The empty string or a string missing a
    ///     scheme or a host is an error.
    ///     - dateFormatter: Dates are formatted by default in ISO8601. Provide another formatter
    ///     to change this behavior.
    ///
    /// - Returns:
    ///     - Initialized URLBuilder
    ///
    /// - Throws:
    ///     - URLError if the string cannot be parsed by URLComponents or is missing a
    ///     scheme or host
    public init(
        _ string: String,
        dateFormatter: DateFormatter? = nil,
        refcode: String? = nil
    ) throws(URLError) {

        guard let components = URLComponents(string: string) else {
            throw .urlInvalid(
                refcode: refcode,
                urlString: string,
                urlComponents: nil)
        }

        guard let scheme = components.scheme else {
            throw .urlMissingScheme(
                refcode: refcode,
                urlString: string,
                urlComponents: components)
        }

        guard let host = components.host else {
            throw .urlMissingHost(
                refcode: refcode,
                urlString: string,
                urlComponents: components)
        }

        self.refcode = refcode
        self.scheme = scheme
        self.host = host
        self.port = components.port
        self.user = components.user
        self.password = components.password
        self.pathSegments = components.path.split(separator: "/").map(String.init)
        self.queryItems = components.queryItems ?? []
        self.overrideDateFormatter = dateFormatter
    }

    /// Initialize a builder from another URL.
    ///
    /// - Parameters:
    ///     - url: A valid URL that includes, at a minimum, a scheme and host.
    ///     - dateFormatter: Dates are formatted by default in ISO8601. Provide another formatter
    ///     to change this behavior.
    ///
    /// - Returns:
    ///     - Initialized URLBuilder
    ///
    /// - Throws:
    ///     - URLError if the string cannot be parsed by URLComponents or is missing
    ///     a scheme or host
    public convenience init(
        _ url: URL,
        dateFormatter: DateFormatter? = nil,
        refcode: String? = nil
    ) throws(URLError) {

        try self.init(
            url.absoluteString,
            dateFormatter: dateFormatter,
            refcode: refcode)
    }

    // MARK: - Build

    /// Create URL from the current builder state.
    ///
    /// - Throws:
    ///     URLError if a URL cannot be created
    ///
    public func build() throws(URLError) -> URL {

        var components = URLComponents()

        guard let scheme else {
            throw .urlMissingScheme(
                refcode: refcode,
                urlString: absoluteString,
                urlComponents: nil)
        }

        components.scheme = scheme

        guard let host else {
            throw .urlMissingHost(
                refcode: refcode,
                urlString: absoluteString,
                urlComponents: components)
        }

        components.host = host

        if let port {
            components.port = port
        }

        if let user, let password {
            components.user = user
            components.password = password
        }

        let path = "/" + pathSegments.joined(separator: "/")
        components.path = path

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw .urlInvalid(
                refcode: refcode,
                urlString: components.string ?? absoluteString,
                urlComponents: components)
        }

        return url
    }

    // MARK: - Base Components

    /// Set the scheme.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - scheme: URL scheme ("http", "https", etc.)
    ///
    /// - Returns:
    ///     - Builder updated with the new scheme
    public func settingScheme(to scheme: String?) -> URLBuilder {
        guard let scheme else { return self }
        self.scheme = scheme
        return self
    }

    /// Set the host.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - host: URL host (name or address)
    ///
    /// - Returns:
    ///     - Builder updated with the new host
    public func settingHost(to host: String?) -> URLBuilder {
        guard let host else { return self }
        self.host = host
        return self
    }

    /// Set the port number.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - port: URL port number
    ///
    /// - Returns:
    ///     - Builder updated with the new port
    public func settingPort(to port: Int?) -> URLBuilder {
        guard let port else { return self }
        self.port = port
        return self
    }

    /// Set the user.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - user: URL username
    ///
    /// - Returns:
    ///     - Builder updated with the new username
    public func settingUser(to user: String?) -> URLBuilder {
        guard let user else { return self }
        self.user = user
        return self
    }

    /// Set the user's password.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - password: URL user password
    ///
    /// - Returns:
    ///     - Builder updated with the new password
    public func settingPassword(to password: String?) -> URLBuilder {
        guard let password else { return self }
        self.password = password
        return self
    }

    // MARK: - Path Component

    /// Append a path segment.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - path: Path segment
    ///
    /// - Returns:
    ///     - Builder updated with the new path segment
    public func appendingPath(_ path: String?) -> URLBuilder {
        guard let path else { return self }
        let segments: [String] = path.split(separator: "/").map(String.init)
        pathSegments.append(contentsOf: segments)
        return self
    }

    // MARK: - Query Items Component

    /// Add boolean query item.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Bool) -> Self {
        addingQueryItem(name: name, value: value ? "true" : "false")
    }

    /// Add integer query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Int?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: String(value))
    }

    /// Add 32-bit integer query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Int32?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: Int(value))
    }

    /// Add 64-bit integer query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Int64?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: String(value))
    }

    /// Add float query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Float?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: Double(value))
    }

    /// Add double query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Double?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: String(value))
    }

    /// Add decimal query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: Decimal?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: String(describing: value))
    }

    /// Add string query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: String?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: value)
    }

    /// Add a UUID query item.
    ///
    /// - Note:
    ///     If the supplied value is nil, the builder is not updated and returned as-is.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(name: String, value: UUID?) -> Self {
        guard let value else { return self }
        return addingQueryItem(name: name, value: value.uuidString)
    }

    /// Add date query item.
    ///
    /// - Note:
    ///     - If the supplied value is nil, the builder is not updated and returned as-is.
    ///     - Date value is converted to a string based on configuration. By default, it is
    ///     converted using the ISO8601 format.
    ///
    /// - Parameters:
    ///     - name: Name for the query item
    ///     - value: Value for the query item
    ///
    /// - Returns:
    ///     - Builder updated with the new query item
    public func addingQueryItem(
        name: String,
        value: Date?,
        dateFormatter: DateFormatter? = nil
    ) -> Self {
        guard let value else { return self }
        let dateString = string(from: value, dateFormatter: dateFormatter)
        return addingQueryItem(name: name, value: dateString)
    }

    // MARK: - Private Implementation

    private func addingQueryItem(name: String, value: String) -> Self {
        queryItems.append(URLQueryItem(name: name, value: value))
        return self
    }

    private func string(from date: Date, dateFormatter: DateFormatter?) -> String {
        if let dateFormatter {
            dateFormatter.string(from: date)
        } else if let overrideDateFormatter {
            overrideDateFormatter.string(from: date)
        } else {
            date.formatted(.iso8601)
        }
    }
}

// MARK: - Utility Extensions

public extension URL {

    init?(string: String?) {
        if let string, let url = URL(string: string) {
            self = url
        } else {
            return nil
        }
    }

    static func from(
        _ string: String,
        refcode: String
    ) throws(URLError) -> URL {
        guard let url = URL(string: string) else {
            throw .urlInvalid(
                refcode: refcode,
                urlString: string,
                urlComponents: nil)
        }

        return url
    }
}
