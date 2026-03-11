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
/// let url = try Earl("http://myhost.com/api/v1")
///     .path("date")
///     .query("date", optionalDate)
///     .query("from", nonOptionalInt)
///     .query("to", optionalInt)
///     .query("isActive", true)
///     .build()```
public final class Earl {

    // MARK: - Fields

    private var scheme: String?
    private var host: String?
    private var port: Int?
    private var user: String?
    private var password: String?

    private var pathSegments: [String]
    private var queryItems: [URLQueryItem] = []
    private let dateFormatter: DateFormatter?

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
            absoluteString.append(queryItems
                .map { "\($0.name)=\($0.value ?? "null")" }.joined(separator: "&"))
        }

        return absoluteString
    }

    // MARK: - Initializerss

    /// Initialize an empty builder.
    ///
    /// - Returns:
    ///     - Initialized Earl
    public init(
        dateFormatter: DateFormatter? = nil,
        refcode: String? = nil,
    ) {
        self.scheme = nil
        self.host = nil
        self.port = nil
        self.user = nil
        self.password = nil
        self.pathSegments = []
        self.queryItems = []
        self.dateFormatter = dateFormatter
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
    ///     - Initialized Earl
    ///
    /// - Throws:
    ///     - EarlError if the string cannot be parsed by URLComponents or is missing a
    ///     scheme or host
    public init(
        _ string: String,
        dateFormatter: DateFormatter? = nil,
        refcode: String? = nil,
    ) throws(EarlError) {

        guard let components = URLComponents(string: string) else {
            throw .invalidURL(
                urlString: string,
                urlComponents: nil,
            )
        }

        guard let scheme = components.scheme else {
            throw .missingScheme(
                urlString: string,
                urlComponents: components,
            )
        }

        guard let host = components.host else {
            throw .missingHost(
                urlString: string,
                urlComponents: components,
            )
        }

        self.scheme = scheme
        self.host = host
        self.port = components.port
        self.user = components.user
        self.password = components.password
        self.pathSegments = components.path.split(separator: "/").map(String.init)
        self.queryItems = components.queryItems ?? []
        self.dateFormatter = dateFormatter
    }

    /// Initialize a builder from another URL.
    ///
    /// - Parameters:
    ///     - url: A valid URL that includes, at a minimum, a scheme and host.
    ///     - dateFormatter: Dates are formatted by default in ISO8601. Provide another formatter
    ///     to change this behavior.
    ///
    /// - Returns:
    ///     - Initialized Earl
    ///
    /// - Throws:
    ///     - EarlError if the string cannot be parsed by URLComponents or is missing
    ///     a scheme or host
    public convenience init(
        _ url: URL,
        dateFormatter: DateFormatter? = nil,
    ) throws(EarlError) {

        try self.init(
            url.absoluteString,
            dateFormatter: dateFormatter,
        )
    }

    // MARK: - Build

    /// Create URL from the current builder state.
    ///
    /// - Throws:
    ///     EarlError if a URL cannot be created
    ///
    public func build() throws(EarlError) -> URL {

        var components = URLComponents()

        guard let scheme else {
            throw .missingScheme(
                urlString: absoluteString,
                urlComponents: nil,
            )
        }

        components.scheme = scheme

        guard let host else {
            throw .missingHost(
                urlString: absoluteString,
                urlComponents: components,
            )
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
            throw .invalidURL(
                urlString: components.string ?? absoluteString,
                urlComponents: components,
            )
        }

        return url
    }

    // MARK: - Base Components

    /// Set the scheme. Nil values are ignored.
    @discardableResult
    public func scheme(_ scheme: String?) -> Earl {
        guard let scheme else { return self }
        self.scheme = scheme
        return self
    }

    /// Set the host. Nil values are ignored.
    @discardableResult
    public func host(_ host: String?) -> Earl {
        guard let host else { return self }
        self.host = host
        return self
    }

    /// Set the port. Nil values are ignored.
    @discardableResult
    public func port(_ port: Int?) -> Earl {
        guard let port else { return self }
        self.port = port
        return self
    }

    /// Set the user. Nil values are ignored.
    @discardableResult
    public func user(_ user: String?) -> Earl {
        guard let user else { return self }
        self.user = user
        return self
    }

    /// Set the password. Nil values are ignored.
    @discardableResult
    public func password(_ password: String?) -> Earl {
        guard let password else { return self }
        self.password = password
        return self
    }

    // MARK: - Path Component

    /// Append a path segment. Nil values are ignored.
    @discardableResult
    public func path(_ path: String?) -> Earl {
        guard let path else { return self }
        let segments: [String] = path.split(separator: "/").map(String.init)
        pathSegments.append(contentsOf: segments)
        return self
    }

    // MARK: - Query Items

    /// Add a Bool query item.
    @discardableResult
    public func query(_ name: String, _ value: Bool) -> Self {
        query(name, value ? "true" : "false")
    }

    /// Add an Int query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Int?) -> Self {
        guard let value else { return self }
        return query(name, String(value))
    }

    /// Add an Int32 query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Int32?) -> Self {
        guard let value else { return self }
        return query(name, Int(value))
    }

    /// Add an Int64 query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Int64?) -> Self {
        guard let value else { return self }
        return query(name, String(value))
    }

    /// Add a Float query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Float?) -> Self {
        guard let value else { return self }
        return query(name, Double(value))
    }

    /// Add a Double query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Double?) -> Self {
        guard let value else { return self }
        return query(name, String(value))
    }

    /// Add a Decimal query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: Decimal?) -> Self {
        guard let value else { return self }
        return query(name, String(describing: value))
    }

    /// Add a String query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: String?) -> Self {
        guard let value else { return self }
        return query(name, value)
    }

    /// Add a UUID query item. Nil values are ignored.
    @discardableResult
    public func query(_ name: String, _ value: UUID?) -> Self {
        guard let value else { return self }
        return query(name, value.uuidString)
    }

    /// Add a Date query item. Nil values are ignored. Dates use ISO8601 by default.
    @discardableResult
    public func query(
        _ name: String,
        _ value: Date?,
        formatter: DateFormatter? = nil,
    ) -> Self {
        guard let value else { return self }
        let dateString = string(from: value, formatter: formatter)
        return query(name, dateString)
    }

    // MARK: - Private Implementation

    private func query(_ name: String, _ value: String) -> Self {
        queryItems.append(URLQueryItem(name: name, value: value))
        return self
    }

    private func string(from date: Date, formatter: DateFormatter?) -> String {
        if let formatter {
            formatter.string(from: date)
        } else if let dateFormatter {
            dateFormatter.string(from: date)
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

    static func from(_ string: String) throws(EarlError) -> URL {

        guard let url = URL(string: string) else {
            throw .invalidURL(urlString: string, urlComponents: nil)
        }

        return url
    }
}
