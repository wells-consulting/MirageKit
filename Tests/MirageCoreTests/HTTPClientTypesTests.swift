//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageCore
import Testing

// MARK: - StatusCode Tests

struct StatusCodeTests {

    @Test("StatusCode - 2xx codes are success")
    func successCodes() {
        let codes: [HTTPClient.StatusCode] = [.ok, .created, .accepted, .noContent, .partialContent]
        for code in codes {
            #expect(code.isSuccess, "Expected \(code.rawValue) to be success")
            #expect(!code.isClientError)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - 4xx codes are client errors")
    func clientErrorCodes() {
        let codes: [HTTPClient.StatusCode] = [.badRequest, .unauthorized, .forbidden, .notFound, .conflict, .tooManyRequests]
        for code in codes {
            #expect(code.isClientError, "Expected \(code.rawValue) to be client error")
            #expect(!code.isSuccess)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - 5xx codes are server errors")
    func serverErrorCodes() {
        let codes: [HTTPClient.StatusCode] = [.internalServerError, .badGateway, .serviceUnavailable, .gatewayTimeout]
        for code in codes {
            #expect(code.isServerError, "Expected \(code.rawValue) to be server error")
            #expect(!code.isSuccess)
            #expect(!code.isClientError)
        }
    }

    @Test("StatusCode - 1xx and 3xx are neither success, client, nor server error")
    func informationalAndRedirectionCodes() {
        let codes: [HTTPClient.StatusCode] = [.continue, .movedPermanently, .found, .notModified, .temporaryRedirect]
        for code in codes {
            #expect(!code.isSuccess)
            #expect(!code.isClientError)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - description includes raw value")
    func descriptionIncludesRawValue() {
        let code = HTTPClient.StatusCode.ok
        #expect(code.description.contains("200"))
    }

    @Test("StatusCode - init from raw value")
    func initFromRawValue() {
        #expect(HTTPClient.StatusCode(rawValue: 200) == .ok)
        #expect(HTTPClient.StatusCode(rawValue: 404) == .notFound)
        #expect(HTTPClient.StatusCode(rawValue: 999) == nil)
    }

    @Test("StatusCode - HTTPURLResponse extension")
    func httpURLResponseExtension() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!
        #expect(response.httpClientStatusCode == .created)

        let unknownResponse = HTTPURLResponse(url: url, statusCode: 999, httpVersion: nil, headerFields: nil)!
        #expect(unknownResponse.httpClientStatusCode == nil)
    }
}

// MARK: - ContentType Tests

struct ContentTypeTests {

    @Test("ContentType - value round-trips for known types")
    func valueRoundTrips() {
        let types: [HTTPClient.ContentType] = [.json, .urlEncodedForm, .text, .binary]
        for type in types {
            let parsed = HTTPClient.ContentType(type.value)
            #expect(parsed != nil, "Expected to parse \(type.value)")
        }
    }

    @Test("ContentType - JSON value")
    func jsonValue() {
        #expect(HTTPClient.ContentType.json.value == "application/json")
    }

    @Test("ContentType - multipart form includes boundary")
    func multipartFormValue() {
        let boundary = "abc123"
        let type = HTTPClient.ContentType.multipartForm(boundary)
        #expect(type.value == "multipart/form-data; boundary=abc123")
    }

    @Test("ContentType - multipart form round-trips")
    func multipartFormRoundTrip() {
        let boundary = "TestBoundary"
        let type = HTTPClient.ContentType.multipartForm(boundary)
        let parsed = HTTPClient.ContentType(type.value)
        #expect(parsed != nil)
        #expect(parsed?.value == type.value)
    }

    @Test("ContentType - empty boundary returns nil")
    func emptyBoundaryReturnsNil() {
        let parsed = HTTPClient.ContentType("multipart/form-data; boundary=")
        #expect(parsed == nil)
    }

    @Test("ContentType - unknown type returns nil")
    func unknownTypeReturnsNil() {
        #expect(HTTPClient.ContentType("image/png") == nil)
        #expect(HTTPClient.ContentType("") == nil)
    }
}

// MARK: - CachePolicy Tests

struct CachePolicyTests {

    @Test("CachePolicy - maps to correct URLRequest.CachePolicy")
    func cachePolicyMapping() {
        #expect(HTTPClient.CachePolicy.default.urlRequestCachePolicy == .useProtocolCachePolicy)
        #expect(HTTPClient.CachePolicy.ignoreCache.urlRequestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(HTTPClient.CachePolicy.returnCacheElseLoad.urlRequestCachePolicy == .returnCacheDataElseLoad)
        #expect(HTTPClient.CachePolicy.returnCacheOnly.urlRequestCachePolicy == .returnCacheDataDontLoad)
        #expect(HTTPClient.CachePolicy.reloadRevalidating.urlRequestCachePolicy == .reloadRevalidatingCacheData)
    }
}

// MARK: - RetryPolicy Backoff Tests

struct RetryPolicyBackoffTests {

    @Test("Backoff - constant delay is always the same")
    func constantBackoff() {
        let backoff = HTTPClient.RetryPolicy.Backoff.constant(2.0)
        #expect(backoff.delay(for: 0) == 2.0)
        #expect(backoff.delay(for: 1) == 2.0)
        #expect(backoff.delay(for: 5) == 2.0)
    }

    @Test("Backoff - exponential doubles each attempt")
    func exponentialBackoff() {
        let backoff = HTTPClient.RetryPolicy.Backoff.exponential(base: 1.0, maximum: 100.0)
        #expect(backoff.delay(for: 0) == 1.0)   // 1 * 2^0 = 1
        #expect(backoff.delay(for: 1) == 2.0)   // 1 * 2^1 = 2
        #expect(backoff.delay(for: 2) == 4.0)   // 1 * 2^2 = 4
        #expect(backoff.delay(for: 3) == 8.0)   // 1 * 2^3 = 8
    }

    @Test("Backoff - exponential is capped at maximum")
    func exponentialCap() {
        let backoff = HTTPClient.RetryPolicy.Backoff.exponential(base: 1.0, maximum: 5.0)
        #expect(backoff.delay(for: 0) == 1.0)
        #expect(backoff.delay(for: 1) == 2.0)
        #expect(backoff.delay(for: 2) == 4.0)
        #expect(backoff.delay(for: 3) == 5.0)   // capped
        #expect(backoff.delay(for: 10) == 5.0)  // still capped
    }

    @Test("Backoff - exponential with custom base")
    func exponentialCustomBase() {
        let backoff = HTTPClient.RetryPolicy.Backoff.exponential(base: 0.5, maximum: 30.0)
        #expect(backoff.delay(for: 0) == 0.5)   // 0.5 * 2^0 = 0.5
        #expect(backoff.delay(for: 1) == 1.0)   // 0.5 * 2^1 = 1.0
        #expect(backoff.delay(for: 2) == 2.0)   // 0.5 * 2^2 = 2.0
    }

    @Test("RetryPolicy - default retryable status codes")
    func defaultRetryableStatusCodes() {
        let defaults = HTTPClient.RetryPolicy.defaultRetryableStatusCodes
        #expect(defaults.contains(408))
        #expect(defaults.contains(429))
        #expect(defaults.contains(502))
        #expect(defaults.contains(503))
        #expect(defaults.contains(504))
        #expect(!defaults.contains(400))
        #expect(!defaults.contains(500))
    }

    @Test("RetryPolicy - default retryable URLError codes")
    func defaultRetryableURLErrorCodes() {
        let defaults = HTTPClient.RetryPolicy.defaultRetryableURLErrorCodes
        #expect(defaults.contains(.timedOut))
        #expect(defaults.contains(.networkConnectionLost))
        #expect(defaults.contains(.notConnectedToInternet))
        #expect(!defaults.contains(.cancelled))
    }
}

// MARK: - LogOptions Tests

struct LogOptionsTests {

    @Test("LogOptions - logAll includes all options")
    func logAllIncludesAll() {
        let all = HTTPClient.LogOptions.logAll
        #expect(all.contains(.request))
        #expect(all.contains(.requestBody))
        #expect(all.contains(.response))
        #expect(all.contains(.responseBody))
    }

    @Test("LogOptions - individual options are distinct")
    func individualOptionsDistinct() {
        let request = HTTPClient.LogOptions.request
        #expect(!request.contains(.requestBody))
        #expect(!request.contains(.response))
        #expect(!request.contains(.responseBody))
    }

    @Test("LogOptions - empty set contains nothing")
    func emptySetContainsNothing() {
        let empty: HTTPClient.LogOptions = []
        #expect(!empty.contains(.request))
        #expect(!empty.contains(.requestBody))
        #expect(!empty.contains(.response))
        #expect(!empty.contains(.responseBody))
    }
}

// MARK: - Method Tests

struct MethodTests {

    @Test("Method - raw values are uppercase HTTP verbs")
    func rawValues() {
        #expect(HTTPClient.Method.get.rawValue == "GET")
        #expect(HTTPClient.Method.post.rawValue == "POST")
        #expect(HTTPClient.Method.put.rawValue == "PUT")
        #expect(HTTPClient.Method.patch.rawValue == "PATCH")
        #expect(HTTPClient.Method.delete.rawValue == "DELETE")
        #expect(HTTPClient.Method.head.rawValue == "HEAD")
        #expect(HTTPClient.Method.options.rawValue == "OPTIONS")
    }
}
