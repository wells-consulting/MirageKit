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
