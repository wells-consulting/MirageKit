//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - StatusCode Tests

struct StatusCodeTests {

    @Test("StatusCode - 2xx codes are success")
    func successCodes() {
        let codes: [Labrador.StatusCode] = [.ok, .created, .accepted, .noContent, .partialContent]
        for code in codes {
            #expect(code.isSuccess, "Expected \(code.rawValue) to be success")
            #expect(!code.isClientError)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - 4xx codes are client errors")
    func clientErrorCodes() {
        let codes: [Labrador.StatusCode] = [.badRequest, .unauthorized, .forbidden, .notFound, .conflict, .tooManyRequests]
        for code in codes {
            #expect(code.isClientError, "Expected \(code.rawValue) to be client error")
            #expect(!code.isSuccess)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - 5xx codes are server errors")
    func serverErrorCodes() {
        let codes: [Labrador.StatusCode] = [.internalServerError, .badGateway, .serviceUnavailable, .gatewayTimeout]
        for code in codes {
            #expect(code.isServerError, "Expected \(code.rawValue) to be server error")
            #expect(!code.isSuccess)
            #expect(!code.isClientError)
        }
    }

    @Test("StatusCode - 1xx and 3xx are neither success, client, nor server error")
    func informationalAndRedirectionCodes() {
        let codes: [Labrador.StatusCode] = [.continue, .movedPermanently, .found, .notModified, .temporaryRedirect]
        for code in codes {
            #expect(!code.isSuccess)
            #expect(!code.isClientError)
            #expect(!code.isServerError)
        }
    }

    @Test("StatusCode - description includes raw value")
    func descriptionIncludesRawValue() {
        let code = Labrador.StatusCode.ok
        #expect(code.description.contains("200"))
    }

    @Test("StatusCode - init from raw value")
    func initFromRawValue() {
        #expect(Labrador.StatusCode(rawValue: 200) == .ok)
        #expect(Labrador.StatusCode(rawValue: 404) == .notFound)
        #expect(Labrador.StatusCode(rawValue: 999) == nil)
    }

    @Test("StatusCode - HTTPURLResponse extension")
    func httpURLResponseExtension() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!
        #expect(response.labradorStatusCode == .created)

        let unknownResponse = HTTPURLResponse(url: url, statusCode: 999, httpVersion: nil, headerFields: nil)!
        #expect(unknownResponse.labradorStatusCode == nil)
    }
}

// MARK: - ContentType Tests

struct ContentTypeTests {

    @Test("ContentType - value round-trips for known types")
    func valueRoundTrips() {
        let types: [Labrador.ContentType] = [.json, .urlEncodedForm, .text, .binary]
        for type in types {
            let parsed = Labrador.ContentType(type.value)
            #expect(parsed != nil, "Expected to parse \(type.value)")
        }
    }

    @Test("ContentType - JSON value")
    func jsonValue() {
        #expect(Labrador.ContentType.json.value == "application/json")
    }

    @Test("ContentType - multipart form includes boundary")
    func multipartFormValue() {
        let boundary = "abc123"
        let type = Labrador.ContentType.multipartForm(boundary)
        #expect(type.value == "multipart/form-data; boundary=abc123")
    }

    @Test("ContentType - multipart form round-trips")
    func multipartFormRoundTrip() {
        let boundary = "TestBoundary"
        let type = Labrador.ContentType.multipartForm(boundary)
        let parsed = Labrador.ContentType(type.value)
        #expect(parsed != nil)
        #expect(parsed?.value == type.value)
    }

    @Test("ContentType - empty boundary returns nil")
    func emptyBoundaryReturnsNil() {
        let parsed = Labrador.ContentType("multipart/form-data; boundary=")
        #expect(parsed == nil)
    }

    @Test("ContentType - unknown type returns nil")
    func unknownTypeReturnsNil() {
        #expect(Labrador.ContentType("image/png") == nil)
        #expect(Labrador.ContentType("") == nil)
    }
}

// MARK: - CachePolicy Tests

struct CachePolicyTests {

    @Test("CachePolicy - maps to correct URLRequest.CachePolicy")
    func cachePolicyMapping() {
        #expect(Labrador.CachePolicy.default.urlRequestCachePolicy == .useProtocolCachePolicy)
        #expect(Labrador.CachePolicy.ignoreCache.urlRequestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(Labrador.CachePolicy.returnCacheElseLoad.urlRequestCachePolicy == .returnCacheDataElseLoad)
        #expect(Labrador.CachePolicy.returnCacheOnly.urlRequestCachePolicy == .returnCacheDataDontLoad)
        #expect(Labrador.CachePolicy.reloadRevalidating.urlRequestCachePolicy == .reloadRevalidatingCacheData)
    }
}

// MARK: - RetryPolicy Backoff Tests

struct RetryPolicyBackoffTests {

    @Test("Backoff - constant delay is always the same")
    func constantBackoff() {
        let backoff = Labrador.RetryPolicy.Backoff.constant(2.0)
        #expect(backoff.delay(for: 0) == 2.0)
        #expect(backoff.delay(for: 1) == 2.0)
        #expect(backoff.delay(for: 5) == 2.0)
    }

    @Test("Backoff - exponential doubles each attempt")
    func exponentialBackoff() {
        let backoff = Labrador.RetryPolicy.Backoff.exponential(base: 1.0, maximum: 100.0)
        #expect(backoff.delay(for: 0) == 1.0)   // 1 * 2^0 = 1
        #expect(backoff.delay(for: 1) == 2.0)   // 1 * 2^1 = 2
        #expect(backoff.delay(for: 2) == 4.0)   // 1 * 2^2 = 4
        #expect(backoff.delay(for: 3) == 8.0)   // 1 * 2^3 = 8
    }

    @Test("Backoff - exponential is capped at maximum")
    func exponentialCap() {
        let backoff = Labrador.RetryPolicy.Backoff.exponential(base: 1.0, maximum: 5.0)
        #expect(backoff.delay(for: 0) == 1.0)
        #expect(backoff.delay(for: 1) == 2.0)
        #expect(backoff.delay(for: 2) == 4.0)
        #expect(backoff.delay(for: 3) == 5.0)   // capped
        #expect(backoff.delay(for: 10) == 5.0)  // still capped
    }

    @Test("Backoff - exponential with custom base")
    func exponentialCustomBase() {
        let backoff = Labrador.RetryPolicy.Backoff.exponential(base: 0.5, maximum: 30.0)
        #expect(backoff.delay(for: 0) == 0.5)   // 0.5 * 2^0 = 0.5
        #expect(backoff.delay(for: 1) == 1.0)   // 0.5 * 2^1 = 1.0
        #expect(backoff.delay(for: 2) == 2.0)   // 0.5 * 2^2 = 2.0
    }

    @Test("RetryPolicy - default retry codes")
    func defaultRetryCodes() {
        let defaults = Labrador.RetryPolicy.defaultRetryCodes
        #expect(defaults.contains(408))
        #expect(defaults.contains(429))
        #expect(defaults.contains(502))
        #expect(defaults.contains(503))
        #expect(defaults.contains(504))
        #expect(!defaults.contains(400))
        #expect(!defaults.contains(500))
    }

    @Test("RetryPolicy - default retry URL errors")
    func defaultRetryURLErrors() {
        let defaults = Labrador.RetryPolicy.defaultRetryURLErrors
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
        let all = Labrador.LogOptions.logAll
        #expect(all.contains(.request))
        #expect(all.contains(.requestBody))
        #expect(all.contains(.response))
        #expect(all.contains(.responseBody))
    }

    @Test("LogOptions - individual options are distinct")
    func individualOptionsDistinct() {
        let request = Labrador.LogOptions.request
        #expect(!request.contains(.requestBody))
        #expect(!request.contains(.response))
        #expect(!request.contains(.responseBody))
    }

    @Test("LogOptions - empty set contains nothing")
    func emptySetContainsNothing() {
        let empty: Labrador.LogOptions = []
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
        #expect(Labrador.Method.get.rawValue == "GET")
        #expect(Labrador.Method.post.rawValue == "POST")
        #expect(Labrador.Method.put.rawValue == "PUT")
        #expect(Labrador.Method.patch.rawValue == "PATCH")
        #expect(Labrador.Method.delete.rawValue == "DELETE")
        #expect(Labrador.Method.head.rawValue == "HEAD")
        #expect(Labrador.Method.options.rawValue == "OPTIONS")
    }
}
