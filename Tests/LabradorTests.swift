//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Configuration Tests

struct LabradorConfigurationTests {

    @Test("Configuration - default values")
    func defaultConfiguration() {
        let config = Labrador.Configuration()
        #expect(config.headers.isEmpty)
        #expect(config.auth == nil)
        #expect(config.urlSession == nil)
        #expect(config.interceptors.isEmpty)
        #expect(config.retryPolicy == nil)
        #expect(config.baseURL == nil)
        #expect(config.timeout == Labrador.defaultTimeout)
    }

    @Test("Configuration - custom timeout")
    func customTimeout() {
        let config = Labrador.Configuration(timeout: 60.0)
        #expect(config.timeout == 60.0)
    }

    @Test("Configuration - custom headers")
    func customHeaders() {
        let headers = ["X-Custom": "value", "Accept-Language": "en"]
        let config = Labrador.Configuration(headers: headers)
        #expect(config.headers == headers)
    }

    @Test("Configuration - base URL")
    func baseURL() {
        let base = URL(string: "https://api.example.com/v1")!
        let config = Labrador.Configuration(baseURL: base)
        #expect(config.baseURL == base)
    }

    @Test("Configuration - cache policy")
    func cachePolicy() {
        let config = Labrador.Configuration(cachePolicy: .ignoreCache)
        #expect(config.cachePolicy.urlRequestCachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test("Configuration - retry policy")
    func retryPolicy() {
        let policy = Labrador.RetryPolicy(maxRetries: 5)
        let config = Labrador.Configuration(retryPolicy: policy)
        #expect(config.retryPolicy?.maxRetries == 5)
    }

    @Test("Default timeout constant")
    func defaultTimeoutConstant() {
        #expect(Labrador.defaultTimeout == 30.0)
    }

    @Test("Configuration - default TLS trust policy is system")
    func defaultTLSTrustPolicy() {
        let config = Labrador.Configuration()
        #expect(config.tlsTrustPolicy == .system)
    }

    @Test("Configuration - custom TLS trust policy")
    func customTLSTrustPolicy() {
        let config = Labrador.Configuration(tlsTrustPolicy: .trustSelfSigned)
        #expect(config.tlsTrustPolicy == .trustSelfSigned)
    }

    #if canImport(Security)
    @Test("Configuration - trustSelfSigned creates session with delegate")
    func trustSelfSignedCreatesDelegate() async {
        let client = Labrador(configuration: .init(tlsTrustPolicy: .trustSelfSigned))
        let session = await client.urlSession
        #expect(session.delegate is SelfSignedCertificateDelegate)
    }

    @Test("Configuration - system policy creates session without delegate")
    func systemPolicyNoDelegate() async {
        let client = Labrador(configuration: .init(tlsTrustPolicy: .system))
        let session = await client.urlSession
        #expect(session.delegate == nil)
    }
    #endif
}

// MARK: - Header Management Tests

struct LabradorHeaderTests {

    @Test("Headers - set and get header")
    func setAndGetHeader() async {
        let client = Labrador()
        await client.setHeader("X-Test", to: "hello")
        let value = await client.header("X-Test")
        #expect(value == "hello")
    }

    @Test("Headers - remove header")
    func removeHeader() async {
        let client = Labrador()
        await client.setHeader("X-Test", to: "hello")
        await client.removeHeader("X-Test")
        let value = await client.header("X-Test")
        #expect(value == nil)
    }

    @Test("Headers - set header to nil removes it")
    func setHeaderToNilRemoves() async {
        let client = Labrador()
        await client.setHeader("X-Test", to: "hello")
        await client.setHeader("X-Test", to: nil)
        let value = await client.header("X-Test")
        #expect(value == nil)
    }

    @Test("Headers - get nonexistent header returns nil")
    func getNonexistentHeader() async {
        let client = Labrador()
        let value = await client.header("X-Does-Not-Exist")
        #expect(value == nil)
    }

    @Test("Headers - overwrite existing header")
    func overwriteHeader() async {
        let client = Labrador()
        await client.setHeader("X-Test", to: "first")
        await client.setHeader("X-Test", to: "second")
        let value = await client.header("X-Test")
        #expect(value == "second")
    }
}

// MARK: - Auth Token Tests

struct LabradorAuthTests {

    @Test("Auth - setAuth sets Bearer header")
    func setAuth() async {
        let client = Labrador()
        let token = OAuthToken(accessToken: "test-token-123", expiration: Date?.none)
        await client.setAuth(token)
        let value = await client.header("Authorization")
        #expect(value == "Bearer test-token-123")
    }

    @Test("Auth - setAuth nil removes Authorization header")
    func setAuthNil() async {
        let client = Labrador()
        let token = OAuthToken(accessToken: "test-token-123", expiration: Date?.none)
        await client.setAuth(token)
        await client.setAuth(nil)
        let value = await client.header("Authorization")
        #expect(value == nil)
    }

    @Test("Auth - setAuth with nil accessToken removes Authorization header")
    func setAuthNilAccessToken() async {
        let client = Labrador()
        await client.setHeader("Authorization", to: "Bearer old")
        let token = OAuthToken(accessToken: nil, expiration: Date?.none)
        await client.setAuth(token)
        let value = await client.header("Authorization")
        #expect(value == nil)
    }

    @Test("Auth - configuration with OAuthToken sets Authorization header on init")
    func configWithOAuthToken() async {
        let token = OAuthToken(accessToken: "init-token", expiration: Date?.none)
        let config = Labrador.Configuration(auth: token)
        let client = Labrador(configuration: config)
        let value = await client.header("Authorization")
        #expect(value == "Bearer init-token")
    }
}

// MARK: - URL Resolution Tests

struct LabradorURLResolutionTests {

    @Test("URL resolution - absolute path without baseURL")
    func absolutePathWithoutBaseURL() async throws {
        let client = Labrador()
        let url = try await client.url(for: "https://api.example.com/users")
        #expect(url.absoluteString == "https://api.example.com/users")
    }

    @Test("URL resolution - relative path with baseURL")
    func relativePathWithBaseURL() async throws {
        let config = Labrador.Configuration(baseURL: URL(string: "https://api.example.com/v1")!)
        let client = Labrador(configuration: config)
        let url = try await client.url(for: "/users")
        #expect(url.absoluteString.contains("api.example.com"))
        #expect(url.absoluteString.contains("/users"))
    }

    @Test("URL resolution - appends query items")
    func appendsQueryItems() async throws {
        let client = Labrador()
        let url = try await client.url(
            for: "https://api.example.com/search",
            queryItems: [
                URLQueryItem(name: "q", value: "swift"),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        #expect(url.absoluteString.contains("q=swift"))
        #expect(url.absoluteString.contains("page=1"))
    }

    @Test("URL resolution - empty query items are ignored")
    func emptyQueryItemsIgnored() async throws {
        let client = Labrador()
        let url = try await client.url(
            for: "https://api.example.com/users",
            queryItems: []
        )
        #expect(!url.absoluteString.contains("?"))
    }

    @Test("URL resolution - nil query items are ignored")
    func nilQueryItemsIgnored() async throws {
        let client = Labrador()
        let url = try await client.url(
            for: "https://api.example.com/users",
            queryItems: nil
        )
        #expect(!url.absoluteString.contains("?"))
    }

    @Test("URL resolution - baseURL appends path component")
    func baseURLAppendsPath() async throws {
        let config = Labrador.Configuration(baseURL: URL(string: "https://api.example.com")!)
        let client = Labrador(configuration: config)
        let url = try await client.url(for: "users/123")
        #expect(url.absoluteString.contains("users/123"))
    }

    @Test("URL resolution - query items merge with existing")
    func queryItemsMerge() async throws {
        let client = Labrador()
        let url = try await client.url(
            for: "https://api.example.com/search?existing=yes",
            queryItems: [URLQueryItem(name: "added", value: "also")]
        )
        #expect(url.absoluteString.contains("existing=yes"))
        #expect(url.absoluteString.contains("added=also"))
    }
}

// MARK: - RequestOptions Tests

struct RequestOptionsTests {

    @Test("RequestOptions - defaults")
    func defaults() {
        let options = Labrador.RequestOptions()
        #expect(options.retryPolicy == nil)
        #expect(options.interceptors.isEmpty)
        #expect(options.skipRetry == false)
    }

    @Test("RequestOptions - skipRetry")
    func skipRetry() {
        let options = Labrador.RequestOptions(skipRetry: true)
        #expect(options.skipRetry == true)
    }

    @Test("RequestOptions - custom retry policy")
    func customRetryPolicy() {
        let policy = Labrador.RetryPolicy(maxRetries: 1, backoff: .constant(0.5))
        let options = Labrador.RequestOptions(retryPolicy: policy)
        #expect(options.retryPolicy?.maxRetries == 1)
    }
}

// MARK: - RetryPolicy Unit Tests

@Suite("RetryPolicy")
struct LabradorRetryPolicyUnitTests {

    @Test("Preset .none has maxRetries 0")
    func nonePreset() {
        #expect(Labrador.RetryPolicy.none.maxRetries == 0)
    }

    @Test("Preset .standard has maxRetries 2")
    func standardPreset() {
        #expect(Labrador.RetryPolicy.standard.maxRetries == 2)
    }

    @Test("Preset .aggressive has maxRetries 4")
    func aggressivePreset() {
        #expect(Labrador.RetryPolicy.aggressive.maxRetries == 4)
    }

    @Test("Backoff.fixed returns sequential delays, clamping at last")
    func fixedBackoffDelays() {
        let backoff = Labrador.RetryPolicy.Backoff.fixed([1.0, 5.0])
        #expect(backoff.delay(for: 0) == 1.0)
        #expect(backoff.delay(for: 1) == 5.0)
        #expect(backoff.delay(for: 2) == 5.0) // last element reused
        #expect(backoff.delay(for: 99) == 5.0)
    }

    @Test("Backoff.fixed with empty array returns zero")
    func fixedBackoffEmpty() {
        let backoff = Labrador.RetryPolicy.Backoff.fixed([])
        #expect(backoff.delay(for: 0) == 0.0)
    }

    @Test("defaultRetryURLErrors includes cannotConnectToHost and cannotFindHost")
    func defaultURLErrors() {
        let errors = Labrador.RetryPolicy.defaultRetryURLErrors
        #expect(errors.contains(.cannotConnectToHost))
        #expect(errors.contains(.cannotFindHost))
        #expect(errors.contains(.timedOut))
        #expect(errors.contains(.networkConnectionLost))
        #expect(errors.contains(.notConnectedToInternet))
    }
}

// MARK: - Retry Integration Tests

/// URLProtocol that serves a pre-configured sequence of responses.
/// Uses a lock for thread safety since URLSession calls it off the main thread.
private final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    typealias Handler = () throws -> (statusCode: Int, data: Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _handlers: [Handler] = []
    nonisolated(unsafe) private static var _callCount: Int = 0

    static var callCount: Int { lock.withLock { _callCount } }

    static func setUp(handlers: [Handler]) {
        lock.withLock {
            _handlers = handlers
            _callCount = 0
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler: Handler? = Self.lock.withLock {
            let i = Self._callCount
            Self._callCount += 1
            return i < Self._handlers.count ? Self._handlers[i] : nil
        }

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (statusCode, data) = try handler()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil,
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private let mockURL = URL(string: "https://test.mirage.internal/api")!

// Serialized because MockURLProtocol uses shared static state.
@Suite("Labrador Retry Behavior", .serialized)
struct LabradorRetryTests {

    @Test("Standard policy retries on transient URLError and eventually succeeds")
    func retriesOnTransientErrorAndSucceeds() async throws {
        MockURLProtocol.setUp(handlers: [
            { throw URLError(.timedOut) },        // attempt 1: fail
            { throw URLError(.timedOut) },        // attempt 2: fail
            { (200, Data("ok".utf8)) },           // attempt 3: succeed
        ])

        let policy = Labrador.RetryPolicy(maxRetries: 2, backoff: .constant(0))
        let client = Labrador(configuration: .init(urlSession: makeMockSession(), retryPolicy: policy))

        var urlRequest = URLRequest(url: mockURL)
        urlRequest.httpMethod = "GET"
        let (_, response) = try await client.data(from: urlRequest)

        #expect(response.statusCode == 200)
        #expect(MockURLProtocol.callCount == 3)
    }

    @Test("No retry policy does not retry on failure")
    func noRetryPolicyDoesNotRetry() async throws {
        MockURLProtocol.setUp(handlers: [
            { throw URLError(.timedOut) },
            { (200, Data("ok".utf8)) },
        ])

        let client = Labrador(configuration: .init(urlSession: makeMockSession(), retryPolicy: nil))

        var urlRequest = URLRequest(url: mockURL)
        urlRequest.httpMethod = "GET"

        await #expect(throws: (any Error).self) {
            try await client.data(from: urlRequest)
        }
        #expect(MockURLProtocol.callCount == 1)
    }

    @Test("Retries on retryable HTTP status code")
    func retriesOnRetryableStatusCode() async throws {
        MockURLProtocol.setUp(handlers: [
            { (503, Data()) },                    // attempt 1: Service Unavailable
            { (200, Data("ok".utf8)) },           // attempt 2: succeed
        ])

        let policy = Labrador.RetryPolicy(maxRetries: 1, backoff: .constant(0))
        let client = Labrador(configuration: .init(urlSession: makeMockSession(), retryPolicy: policy))

        var urlRequest = URLRequest(url: mockURL)
        urlRequest.httpMethod = "GET"
        let (_, response) = try await client.data(from: urlRequest)

        #expect(response.statusCode == 200)
        #expect(MockURLProtocol.callCount == 2)
    }

    @Test("Retries exhausted throws error")
    func retriesExhaustedThrowsError() async throws {
        MockURLProtocol.setUp(handlers: [
            { throw URLError(.timedOut) },
            { throw URLError(.timedOut) },
            { throw URLError(.timedOut) },
        ])

        let policy = Labrador.RetryPolicy(maxRetries: 2, backoff: .constant(0))
        let client = Labrador(configuration: .init(urlSession: makeMockSession(), retryPolicy: policy))

        var urlRequest = URLRequest(url: mockURL)
        urlRequest.httpMethod = "GET"

        await #expect(throws: (any Error).self) {
            try await client.data(from: urlRequest)
        }
        #expect(MockURLProtocol.callCount == 3)
    }

    @Test("skipRetry option bypasses client retry policy")
    func skipRetryBypassesPolicy() async throws {
        MockURLProtocol.setUp(handlers: [
            { throw URLError(.timedOut) },
            { (200, Data("ok".utf8)) },
        ])

        let policy = Labrador.RetryPolicy(maxRetries: 2, backoff: .constant(0))
        let client = Labrador(configuration: .init(urlSession: makeMockSession(), retryPolicy: policy))

        var urlRequest = URLRequest(url: mockURL)
        urlRequest.httpMethod = "GET"

        await #expect(throws: (any Error).self) {
            try await client.data(from: urlRequest, options: .init(skipRetry: true))
        }
        #expect(MockURLProtocol.callCount == 1)
    }
}
