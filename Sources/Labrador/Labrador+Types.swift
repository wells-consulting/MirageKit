//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - LogOptions

public extension Labrador {

    /// Controls which parts of each HTTP exchange Labrador writes to the log.
    struct LogOptions: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Log the outgoing request line (method, URL, size).
        public static let request = LogOptions(rawValue: 1 << 1)
        /// Log the serialized request body alongside the request line.
        public static let requestBody = LogOptions(rawValue: 1 << 2)
        /// Log the incoming response line (status code, size, duration).
        public static let response = LogOptions(rawValue: 1 << 3)
        /// Log the raw response body alongside the response line.
        public static let responseBody = LogOptions(rawValue: 1 << 4)

        /// Convenience preset that enables all four log options.
        public static let logAll: LogOptions = [
            .request, .requestBody, .response, .responseBody,
        ]
    }
}

// MARK: - CachePolicy

public extension Labrador {

    enum CachePolicy: Sendable {
        /// Use cached data if available and not expired; otherwise fetch from the network.
        case `default`
        /// Always fetch from the network, ignoring cached data.
        case ignoreCache
        /// Return cached data if available, regardless of expiration. Fetch from the network only if no cached data exists.
        case returnCacheElseLoad
        /// Return cached data if available, regardless of expiration. Do not fetch from the network.
        case returnCacheOnly
        /// Reload from the network, but update the cache with the response.
        case reloadRevalidating

        var urlRequestCachePolicy: URLRequest.CachePolicy {
            switch self {
            case .default:
                .useProtocolCachePolicy
            case .ignoreCache:
                .reloadIgnoringLocalCacheData
            case .returnCacheElseLoad:
                .returnCacheDataElseLoad
            case .returnCacheOnly:
                .returnCacheDataDontLoad
            case .reloadRevalidating:
                .reloadRevalidatingCacheData
            }
        }
    }
}

// MARK: - RetryPolicy

public extension Labrador {

    /// A configurable policy for retrying failed requests due to transient
    /// network errors or retryable HTTP status codes (e.g., 408, 429, 503).
    struct RetryPolicy: Sendable {

        /// The maximum number of retry attempts (not counting the initial request).
        public let maxRetries: Int

        /// The backoff strategy used to compute the delay between retries.
        public let backoff: Backoff

        /// HTTP status codes that should trigger a retry.
        public let retryCodes: Set<Int>

        /// Foundation.URLError codes that should trigger a retry.
        public let retryURLErrors: Set<Foundation.URLError.Code>

        public enum Backoff: Sendable {
            /// A constant delay between retries.
            case constant(TimeInterval)
            /// Exponential backoff: `base * 2^attempt`, capped at `maximum`.
            case exponential(base: TimeInterval = 1.0, maximum: TimeInterval = 30.0)
            /// A fixed sequence of delays. `delays[0]` is used before the 2nd attempt,
            /// `delays[1]` before the 3rd, etc. The last element is reused when
            /// `attempt` exceeds the array bounds.
            case fixed([TimeInterval])

            func delay(for attempt: Int) -> TimeInterval {
                switch self {
                case let .constant(interval):
                    interval
                case let .exponential(base, maximum):
                    min(base * pow(2.0, Double(attempt)), maximum)
                case let .fixed(delays):
                    delays.isEmpty ? 0 : delays[min(attempt, delays.count - 1)]
                }
            }
        }

        /// The default set of HTTP status codes considered retryable.
        public static let defaultRetryCodes: Set<Int> = [
            408, // Request Timeout
            429, // Too Many Requests
            502, // Bad Gateway
            503, // Service Unavailable
            504, // Gateway Timeout
        ]

        /// The default set of URLError codes considered retryable.
        public static let defaultRetryURLErrors: Set<Foundation.URLError.Code> = [
            .timedOut,
            .networkConnectionLost,
            .notConnectedToInternet,
            .cannotConnectToHost,
            .cannotFindHost,
        ]

        /// No retries — the first failure is thrown immediately.
        public static let none = RetryPolicy(maxRetries: 0, backoff: .constant(0))

        /// Three total attempts (two retries) with 1s then 5s delays.
        public static let standard = RetryPolicy(maxRetries: 2, backoff: .fixed([1, 5]))

        /// Five total attempts (four retries) with progressively longer delays.
        public static let aggressive = RetryPolicy(maxRetries: 4, backoff: .fixed([1, 3, 10, 30]))

        public init(
            maxRetries: Int = 3,
            backoff: Backoff = .exponential(),
            retryCodes: Set<Int> = Self.defaultRetryCodes,
            retryURLErrors: Set<Foundation.URLError.Code> = Self.defaultRetryURLErrors,
        ) {
            self.maxRetries = maxRetries
            self.backoff = backoff
            self.retryCodes = retryCodes
            self.retryURLErrors = retryURLErrors
        }
    }
}

// MARK: - Interceptor

public extension Labrador {

    /// An interceptor that can modify requests before they are sent and inspect
    /// responses before they are returned to the caller.
    ///
    /// Interceptors are called in order for requests and in reverse order for
    /// responses. Each interceptor receives a `proceed` closure that forwards
    /// the (possibly modified) request to the next interceptor in the chain, or
    /// to the network if it is the last one. An interceptor may call `proceed`
    /// zero or more times — for example, to retry a request after refreshing a
    /// token on a 401 response.
    typealias Interceptor = @Sendable (
        _ request: URLRequest,
        _ proceed: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse),
    ) async throws -> (Data, HTTPURLResponse)
}

// MARK: - RequestOptions

public extension Labrador {

    /// Per-request overrides for retry and interceptor behavior.
    struct RequestOptions: Sendable {

        /// Override the client-level retry policy for this request.
        /// Set to a custom policy to change retry behavior,
        /// or use `.disabled` to disable retries entirely.
        public let retryPolicy: RetryPolicy?

        /// Additional interceptors applied after the client-level interceptors
        /// for this request only.
        public let interceptors: [Interceptor]

        /// Whether to skip the client-level retry policy for this request.
        public let skipRetry: Bool

        public init(
            retryPolicy: RetryPolicy? = nil,
            interceptors: [Interceptor] = [],
            skipRetry: Bool = false,
        ) {
            self.retryPolicy = retryPolicy
            self.interceptors = interceptors
            self.skipRetry = skipRetry
        }
    }
}

// MARK: - TLSTrustPolicy

public extension Labrador {

    /// Controls how Labrador evaluates server TLS certificates.
    enum TLSTrustPolicy: Sendable {
        /// Use the system default trust evaluation (rejects self-signed certificates).
        case system
        /// Accept any server certificate, including self-signed.
        /// Use only for servers the user has explicitly opted into trusting.
        case trustSelfSigned
    }
}

// MARK: - Configuration

public extension Labrador {

    /// Client-wide settings passed to ``Labrador/init(configuration:)``.
    ///
    /// All properties have sensible defaults; only supply the ones you need.
    struct Configuration: Sendable {

        let json: Jayson
        let logOptions: LogOptions
        let headers: [String: String]
        let auth: OAuthToken?
        let urlSession: URLSession?
        let cachePolicy: CachePolicy
        let interceptors: [Interceptor]
        let retryPolicy: RetryPolicy?
        let baseURL: URL?
        let timeout: TimeInterval
        let tlsTrustPolicy: TLSTrustPolicy

        public init(
            urlSession: URLSession? = nil,
            baseURL: URL? = nil,
            headers: [String: String] = [:],
            auth: OAuthToken? = nil,
            json: Jayson? = nil,
            logOptions: LogOptions = [],
            cachePolicy: CachePolicy = .default,
            interceptors: [Interceptor] = [],
            retryPolicy: RetryPolicy? = nil,
            timeout: TimeInterval = Labrador.defaultTimeout,
            tlsTrustPolicy: TLSTrustPolicy = .system,
        ) {
            self.urlSession = urlSession
            self.baseURL = baseURL
            self.headers = headers
            self.auth = auth
            self.json = json ?? .shared
            self.logOptions = logOptions
            self.cachePolicy = cachePolicy
            self.interceptors = interceptors
            self.retryPolicy = retryPolicy
            self.timeout = timeout
            self.tlsTrustPolicy = tlsTrustPolicy
        }
    }
}

// MARK: - Method

public extension Labrador {

    /// The HTTP method used for a request.
    enum Method: String, Sendable {
        case delete = "DELETE"
        case get = "GET"
        case head = "HEAD"
        case options = "OPTIONS"
        case patch = "PATCH"
        case post = "POST"
        case put = "PUT"
    }
}

// MARK: - ContentType

public extension Labrador {

    /// The `Content-Type` of an HTTP request body.
    enum ContentType: Sendable {

        /// `application/json`
        case json
        /// `multipart/form-data` with the given boundary string.
        case multipartForm(String)
        /// `application/x-www-form-urlencoded`
        case urlEncodedForm
        /// `text/plain`
        case text
        /// `application/octet-stream`
        case binary

        var value: String {
            switch self {
            case .json:
                "application/json"
            case let .multipartForm(boundary):
                "multipart/form-data; boundary=\(boundary)"
            case .urlEncodedForm:
                "application/x-www-form-urlencoded"
            case .text:
                "text/plain"
            case .binary:
                "application/octet-stream"
            }
        }

        init?(_ text: String) {
            switch text {
            case "application/json":
                self = .json
            case _ where text.hasPrefix("multipart/form-data; boundary="):
                let boundary = String(text.dropFirst("multipart/form-data; boundary=".count))
                if !boundary.isEmpty {
                    self = .multipartForm(boundary)
                } else {
                    return nil
                }
            case "application/x-www-form-urlencoded":
                self = .urlEncodedForm
            case "text/plain":
                self = .text
            case "application/octet-stream":
                self = .binary
            default:
                return nil
            }
        }
    }
}

// MARK: - StatusCode

public extension Labrador {

    enum StatusCode: Int, Codable, CustomStringConvertible, Sendable {

        // 1XX

        case `continue` = 100
        case switchingProtocols = 101
        case processing = 102

        // 2XX

        case ok = 200
        case created = 201
        case accepted = 202
        case nonAuthoritativeInformation = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207 // WebDAV
        case alreadyReported = 208 // WebDAV
        case imUsed = 226

        // 3XX

        case multipleChoices = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case useProxy = 305
        case switchProxy = 306
        case temporaryRedirect = 307
        case permanentRedirect = 308

        // 4XX

        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthenticationRequired = 407
        case requestTimeout = 408
        case conflict = 409
        case gone = 410
        case lengthRequired = 411
        case preconditionFailed = 412
        case payloadTooLarge = 413
        case uriTooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case imATeapot = 418
        case misdirectedRequest = 421
        case unprocessableEntity = 422 // WebDAV
        case locked = 423 // WebDAV
        case failedDependency = 424 // WebDAV
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case requestHeaderFieldsTooLarge = 431
        case unavailableForLegalReasons = 451

        // 5XX

        case internalServerError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case httpVersionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficientStorage = 507 // WebDAV
        case loopDetected = 508 // WebDAV
        case notExtended = 510
        case networkAuthenticationRequired = 511

        /// `true` for 2xx status codes.
        public var isSuccess: Bool { rawValue >= 200 && rawValue < 300 }
        /// `true` for 4xx status codes.
        public var isClientError: Bool { rawValue >= 400 && rawValue < 500 }
        /// `true` for 5xx status codes.
        public var isServerError: Bool { rawValue >= 500 && rawValue < 600 }

        public var description: String {
            "\(rawValue) " + HTTPURLResponse.localizedString(forStatusCode: rawValue)
        }
    }
}

// MARK: - Response

public extension Labrador {

    /// A typed response that includes both the decoded value and the raw HTTP response metadata.
    struct Response<Value: Sendable>: Sendable {

        /// The decoded response value.
        public let value: Value

        /// The underlying HTTP response, providing access to status code, headers, etc.
        public let httpResponse: HTTPURLResponse

        /// The HTTP status code of the response.
        public var statusCode: Int { httpResponse.statusCode }

        /// Retrieves the value of a response header.
        public func header(_ name: String) -> String? {
            httpResponse.value(forHTTPHeaderField: name)
        }
    }
}

// MARK: - Extensions

public extension HTTPURLResponse {
    /// The HTTP status code as a typed ``Labrador/StatusCode``, or `nil` if
    /// the raw integer value is not a recognised status code.
    var labradorStatusCode: Labrador.StatusCode? {
        .init(rawValue: statusCode)
    }
}
