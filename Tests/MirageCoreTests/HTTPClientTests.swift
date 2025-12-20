//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageCore
import Testing

// MARK: - Configuration Tests

struct HTTPClientConfigurationTests {

    @Test("Configuration - default values")
    func defaultConfiguration() {
        let config = HTTPClient.Configuration()
        #expect(config.headers.isEmpty)
        #expect(config.oAuthToken == nil)
        #expect(config.urlSession == nil)
        #expect(config.interceptors.isEmpty)
        #expect(config.retryPolicy == nil)
        #expect(config.baseURL == nil)
        #expect(config.timeout == HTTPClient.defaultRequestTimeout)
    }

    @Test("Configuration - custom timeout")
    func customTimeout() {
        let config = HTTPClient.Configuration(timeout: 60.0)
        #expect(config.timeout == 60.0)
    }

    @Test("Configuration - custom headers")
    func customHeaders() {
        let headers = ["X-Custom": "value", "Accept-Language": "en"]
        let config = HTTPClient.Configuration(headers: headers)
        #expect(config.headers == headers)
    }

    @Test("Configuration - base URL")
    func baseURL() {
        let base = URL(string: "https://api.example.com/v1")!
        let config = HTTPClient.Configuration(baseURL: base)
        #expect(config.baseURL == base)
    }

    @Test("Configuration - cache policy")
    func cachePolicy() {
        let config = HTTPClient.Configuration(cachePolicy: .ignoreCache)
        #expect(config.cachePolicy.urlRequestCachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test("Configuration - retry policy")
    func retryPolicy() {
        let policy = HTTPClient.RetryPolicy(maxRetries: 5)
        let config = HTTPClient.Configuration(retryPolicy: policy)
        #expect(config.retryPolicy?.maxRetries == 5)
    }

    @Test("Default timeout constant")
    func defaultTimeoutConstant() {
        #expect(HTTPClient.defaultRequestTimeout == 30.0)
    }
}

// MARK: - Header Management Tests

struct HTTPClientHeaderTests {

    @Test("Headers - set and get header")
    func setAndGetHeader() async {
        let client = HTTPClient()
        await client.setHeader(name: "X-Test", value: "hello")
        let value = await client.header("X-Test")
        #expect(value == "hello")
    }

    @Test("Headers - remove header")
    func removeHeader() async {
        let client = HTTPClient()
        await client.setHeader(name: "X-Test", value: "hello")
        await client.removeHeader("X-Test")
        let value = await client.header("X-Test")
        #expect(value == nil)
    }

    @Test("Headers - set header to nil removes it")
    func setHeaderToNilRemoves() async {
        let client = HTTPClient()
        await client.setHeader(name: "X-Test", value: "hello")
        await client.setHeader(name: "X-Test", value: nil)
        let value = await client.header("X-Test")
        #expect(value == nil)
    }

    @Test("Headers - get nonexistent header returns nil")
    func getNonexistentHeader() async {
        let client = HTTPClient()
        let value = await client.header("X-Does-Not-Exist")
        #expect(value == nil)
    }

    @Test("Headers - overwrite existing header")
    func overwriteHeader() async {
        let client = HTTPClient()
        await client.setHeader(name: "X-Test", value: "first")
        await client.setHeader(name: "X-Test", value: "second")
        let value = await client.header("X-Test")
        #expect(value == "second")
    }
}

// MARK: - Auth Token Tests

struct HTTPClientAuthTests {

    @Test("Auth - setAuthToken sets Bearer header")
    func setAuthToken() async {
        let client = HTTPClient()
        let token = OAuthToken(accessToken: "test-token-123", expiration: Date?.none)
        await client.setAuthToken(token)
        let value = await client.header("Authorization")
        #expect(value == "Bearer test-token-123")
    }

    @Test("Auth - setAuthToken nil removes Authorization header")
    func setAuthTokenNil() async {
        let client = HTTPClient()
        let token = OAuthToken(accessToken: "test-token-123", expiration: Date?.none)
        await client.setAuthToken(token)
        await client.setAuthToken(nil)
        let value = await client.header("Authorization")
        #expect(value == nil)
    }

    @Test("Auth - setAuthToken with nil accessToken removes Authorization header")
    func setAuthTokenNilAccessToken() async {
        let client = HTTPClient()
        await client.setHeader(name: "Authorization", value: "Bearer old")
        let token = OAuthToken(accessToken: nil, expiration: Date?.none)
        await client.setAuthToken(token)
        let value = await client.header("Authorization")
        #expect(value == nil)
    }

    @Test("Auth - configuration with OAuthToken sets Authorization header on init")
    func configWithOAuthToken() async {
        let token = OAuthToken(accessToken: "init-token", expiration: Date?.none)
        let config = HTTPClient.Configuration(oAuthToken: token)
        let client = HTTPClient(configuration: config)
        let value = await client.header("Authorization")
        #expect(value == "Bearer init-token")
    }
}

// MARK: - URL Resolution Tests

struct HTTPClientURLResolutionTests {

    @Test("URL resolution - absolute path without baseURL")
    func absolutePathWithoutBaseURL() async throws {
        let client = HTTPClient()
        let url = try await client.url(for: "https://api.example.com/users")
        #expect(url.absoluteString == "https://api.example.com/users")
    }

    @Test("URL resolution - relative path with baseURL")
    func relativePathWithBaseURL() async throws {
        let config = HTTPClient.Configuration(baseURL: URL(string: "https://api.example.com/v1")!)
        let client = HTTPClient(configuration: config)
        let url = try await client.url(for: "/users")
        #expect(url.absoluteString.contains("api.example.com"))
        #expect(url.absoluteString.contains("/users"))
    }

    @Test("URL resolution - appends query items")
    func appendsQueryItems() async throws {
        let client = HTTPClient()
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
        let client = HTTPClient()
        let url = try await client.url(
            for: "https://api.example.com/users",
            queryItems: []
        )
        #expect(!url.absoluteString.contains("?"))
    }

    @Test("URL resolution - nil query items are ignored")
    func nilQueryItemsIgnored() async throws {
        let client = HTTPClient()
        let url = try await client.url(
            for: "https://api.example.com/users",
            queryItems: nil
        )
        #expect(!url.absoluteString.contains("?"))
    }

    @Test("URL resolution - baseURL appends path component")
    func baseURLAppendsPath() async throws {
        let config = HTTPClient.Configuration(baseURL: URL(string: "https://api.example.com")!)
        let client = HTTPClient(configuration: config)
        let url = try await client.url(for: "users/123")
        #expect(url.absoluteString.contains("users/123"))
    }

    @Test("URL resolution - query items merge with existing")
    func queryItemsMerge() async throws {
        let client = HTTPClient()
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
        let options = HTTPClient.RequestOptions()
        #expect(options.retryPolicy == nil)
        #expect(options.interceptors.isEmpty)
        #expect(options.skipRetry == false)
    }

    @Test("RequestOptions - skipRetry")
    func skipRetry() {
        let options = HTTPClient.RequestOptions(skipRetry: true)
        #expect(options.skipRetry == true)
    }

    @Test("RequestOptions - custom retry policy")
    func customRetryPolicy() {
        let policy = HTTPClient.RetryPolicy(maxRetries: 1, backoff: .constant(0.5))
        let options = HTTPClient.RequestOptions(retryPolicy: policy)
        #expect(options.retryPolicy?.maxRetries == 1)
    }
}
