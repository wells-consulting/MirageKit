//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public actor HTTPClient {

    let urlSession: URLSession
    var additionalHeaders: [String: String] = [:]
    private let logOptions: LogOptions
    let jsonCoder: JSONCoder
    private let log: Timber
    private let interceptors: [Interceptor]
    private let retryPolicy: RetryPolicy?
    private let baseURL: URL?
    let defaultTimeout: TimeInterval

    /// The default request timeout interval in seconds.
    public static let defaultRequestTimeout: TimeInterval = 30.0

    // MARK: - Initializer

    public init(configuration: Configuration = .init()) {

        if let urlSession = configuration.urlSession {
            self.urlSession = urlSession
        } else {
            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.httpAdditionalHeaders = configuration.headers
            urlSessionConfiguration.timeoutIntervalForRequest = configuration.timeout
            urlSessionConfiguration.httpCookieStorage = HTTPCookieStorage.shared
            urlSessionConfiguration.requestCachePolicy = configuration.cachePolicy.urlRequestCachePolicy
            self.urlSession = URLSession(configuration: urlSessionConfiguration)
        }

        self.logOptions = configuration.logOptions
        self.jsonCoder = configuration.jsonCoder
        self.interceptors = configuration.interceptors
        self.retryPolicy = configuration.retryPolicy
        self.baseURL = configuration.baseURL
        self.defaultTimeout = configuration.timeout

        if let accessToken = configuration.oAuthToken?.accessToken {
            additionalHeaders["Authorization"] = "Bearer \(accessToken)"
        }

        self.log = Timber(subsystem: Bundle.appName, category: #fileID)
    }

    // MARK: - Dispatch

    private nonisolated(unsafe) static let requestCounter = RequestCounter()

    func request(
        _ clientRequest: ClientRequest,
        options: RequestOptions? = nil,
    ) async throws -> (Data, HTTPURLResponse) {

        // Support cooperative cancellation: bail out early if already cancelled
        try Task.checkCancellation()

        let logOptions = clientRequest.logOptions ?? logOptions

        if logOptions.contains(.request) {
            if logOptions.contains(.requestBody), let summary = clientRequest.payloadSummary {
                log.debug("\(clientRequest.requestSummary): \(summary)")
            } else {
                log.debug(clientRequest.requestSummary)
            }
        }

        let shouldLogResponse = logOptions.contains(.response)
        let shouldLogResponseBody = logOptions.contains(.responseBody)

        var urlRequest = clientRequest.urlRequest

        for (name, value) in additionalHeaders {
            if urlRequest.allHTTPHeaderFields == nil {
                urlRequest.allHTTPHeaderFields = [name: value]
            } else {
                urlRequest.allHTTPHeaderFields?[name] = value
            }
        }

        // Build the interceptor chain around the network call.
        // The innermost function performs the actual URLSession request.

        let session = urlSession

        let networkCall: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse) = { request in
            let data: Data
            let urlResponse: URLResponse

            do {
                let (_data, _urlResponse) = try await session.data(for: request)
                data = _data
                urlResponse = _urlResponse
            } catch is CancellationError {
                throw CancellationError()
            } catch let urlError as Foundation.URLError where urlError.code == .cancelled {
                throw CancellationError()
            } catch let urlError as Foundation.URLError {
                throw HTTPError(
                    summary: Self.summary(for: urlError),
                    underlyingErrors: [urlError],
                    clientRequest: clientRequest,
                )
            } catch {
                throw HTTPError(
                    summary: "Could not complete the network request due to an unexpected error.",
                    underlyingErrors: [error],
                    clientRequest: clientRequest,
                )
            }

            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
                throw HTTPError(
                    summary: "Could not complete the network request because a non-HTTP URL response was received.",
                    clientRequest: clientRequest,
                    responseData: data,
                )
            }

            return (data, httpURLResponse)
        }

        // Fold interceptors in reverse so that the first interceptor in the
        // array is the outermost (called first for requests, last for responses).

        let allInterceptors = interceptors + (options?.interceptors ?? [])

        let chain = allInterceptors.reversed().reduce(networkCall) { next, interceptor in
            { request in
                try await interceptor(request, next)
            }
        }

        // Execute the chain with optional retry logic.

        let effectiveRetryPolicy: RetryPolicy? =
            if options?.skipRetry == true {
                nil
            } else {
                options?.retryPolicy ?? retryPolicy
            }

        let maxAttempts = (effectiveRetryPolicy?.maxRetries ?? 0) + 1
        var lastError: (any Error)?
        var data: Data?
        var httpURLResponse: HTTPURLResponse?

        for attempt in 0 ..< maxAttempts {
            try Task.checkCancellation()

            // Wait before retrying (not on the first attempt)
            if attempt > 0, let effectiveRetryPolicy {
                let delay = effectiveRetryPolicy.backoff.delay(for: attempt - 1)
                log.debug("[\(clientRequest.id)] Retry \(attempt)/\(effectiveRetryPolicy.maxRetries) after \(String(format: "%.1f", delay))s")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                try Task.checkCancellation()
            }

            do {
                let (responseData, response) = try await chain(urlRequest)

                // Check if the status code is retryable
                if let effectiveRetryPolicy, attempt < maxAttempts - 1,
                   effectiveRetryPolicy.retryableStatusCodes.contains(response.statusCode)
                {
                    data = responseData
                    httpURLResponse = response
                    lastError = HTTPError(
                        summary: "Could not complete the network request because error status was received. Reference: \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode).capitalized).",
                        clientRequest: clientRequest,
                        httpURLResponse: response,
                        responseData: responseData,
                    )
                    continue
                }

                data = responseData
                httpURLResponse = response
                lastError = nil
                break

            } catch is CancellationError {
                throw CancellationError()
            } catch let error as HTTPError {
                // Check if the underlying URLError is retryable
                let isRetryable = error.underlyingErrors?.contains { underlyingError in
                    guard let urlError = underlyingError as? Foundation.URLError else { return false }
                    return effectiveRetryPolicy?.retryableURLErrorCodes.contains(urlError.code) == true
                } ?? false

                if isRetryable, attempt < maxAttempts - 1 {
                    lastError = error
                    continue
                }

                throw error
            } catch {
                throw error
            }
        }

        guard let data, let httpURLResponse else {
            throw lastError ?? HTTPError(
                summary: "Could not complete the network request after \(maxAttempts) attempts.",
                clientRequest: clientRequest,
            )
        }

        // If we exhausted retries on a retryable status code, fall through
        // to the normal status-code validation below which will throw.

        let httpResponse = ClientResponse(
            clientRequest: clientRequest,
            urlResponse: httpURLResponse,
            data: data,
        )

        if shouldLogResponse {
            let message = httpResponse.logDescription(includeResponseBody: shouldLogResponseBody)
            log.debug(message)
        }

        // Unrecoverable error: status code must be known

        guard let statusCode = StatusCode(rawValue: httpURLResponse.statusCode) else {
            throw HTTPError(
                summary: "Could not complete the network request because an error status was not handled. Reference: \(httpURLResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpURLResponse.statusCode).capitalized).",
                clientRequest: clientRequest,
                httpURLResponse: httpURLResponse,
                responseData: data,
            )
        }

        // Failure is not an option

        guard statusCode.isSuccess else {
            throw HTTPError(
                summary: "Could not complete the network request because error status was received. Reference: \(statusCode.description).",
                clientRequest: clientRequest,
                httpURLResponse: httpURLResponse,
                responseData: data,
            )
        }

        return (data, httpURLResponse)
    }

    private static func summary(for error: Foundation.URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            "Could not complete the network request because the device is not connected to the internet."
        case .networkConnectionLost:
            "Could not complete the network request because the network connection was lost."
        case .timedOut:
            "Could not complete the network request because it timed out."
        case .cannotFindHost, .dnsLookupFailed:
            "Could not complete the network request because the server could not be found."
        case .cannotConnectToHost:
            "Could not complete the network request because a connection to the server could not be established."
        case .secureConnectionFailed:
            "Could not complete the network request because a secure connection could not be established."
        case .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            "Could not complete the network request because the server's certificate is not trusted."
        case .dataNotAllowed:
            "Could not complete the network request because cellular data is disabled."
        case .internationalRoamingOff:
            "Could not complete the network request because international roaming is turned off."
        default:
            "Could not complete the network request because the server did not respond."
        }
    }

    // MARK: - Headers

    public func header(_ name: String) -> String? {
        additionalHeaders[name]
    }

    public func setHeader(name: String, value: String?) {
        if let value {
            additionalHeaders.updateValue(value, forKey: name)
        } else {
            removeHeader(name)
        }
    }

    public func removeHeader(_ name: String) {
        additionalHeaders.removeValue(forKey: name)
    }

    // MARK: - Helpers

    public func setAuthToken(_ authToken: OAuthToken?) {
        if let accessToken = authToken?.accessToken {
            setHeader(name: "Authorization", value: "Bearer \(accessToken)")
        } else {
            removeHeader("Authorization")
        }
    }

    // MARK: - URL Resolution

    /// Resolves a path string against the configured `baseURL`.
    /// If no `baseURL` is configured, the path is treated as an absolute URL string.
    ///
    /// - Parameters:
    ///   - path: A relative path (e.g., `"/users/123"`) or absolute URL string.
    ///   - queryItems: Optional query parameters to append.
    /// - Returns: A fully resolved `URL`.
    /// - Throws: `URLError` if the resulting URL is invalid.
    public func url(
        for path: String,
        queryItems: [URLQueryItem]? = nil,
    ) throws -> URL {

        var components: URLComponents?

        if let baseURL {
            let resolved = baseURL.appendingPathComponent(path)
            components = URLComponents(url: resolved, resolvingAgainstBaseURL: true)
        } else {
            components = URLComponents(string: path)
        }

        guard var urlComponents = components else {
            throw URLError.urlInvalid(urlString: path, urlComponents: nil)
        }

        if let queryItems, !queryItems.isEmpty {
            let existing = urlComponents.queryItems ?? []
            urlComponents.queryItems = existing + queryItems
        }

        guard let url = urlComponents.url else {
            throw URLError.urlInvalid(urlString: path, urlComponents: urlComponents)
        }

        return url
    }
}

// MARK: - Simple Request

public extension HTTPClient {

    func data(
        from urlRequest: URLRequest,
        options: RequestOptions? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> (Data, HTTPURLResponse) {

        let clientRequest = ClientRequest(
            urlRequest: urlRequest,
            logOptions: logOptions,
        )

        return try await request(clientRequest, options: options)
    }

    func data<Output: Decodable>(
        from urlRequest: URLRequest,
        decoding type: Output.Type,
        options: RequestOptions? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        let clientRequest = ClientRequest(
            urlRequest: urlRequest,
            logOptions: logOptions,
        )

        let (data, _) = try await request(clientRequest, options: options)
        return try jsonCoder.decode(type, from: data, userInfo: nil)
    }
}

// MARK: - ClientRequest

extension HTTPClient {

    struct ClientRequest {

        let id: Int
        let urlRequest: URLRequest
        let requestSummary: String
        let payloadSummary: String?
        let timestamp: Date = .init()
        let logOptions: LogOptions?

        static let defaultTimeout: TimeInterval = HTTPClient.defaultRequestTimeout

        init(
            url: URL,
            method: Method,
            payload: Payload?,
            accept: ContentType? = nil,
            logOptions: LogOptions? = nil,
            headers: [String: String]?,
            timeout: TimeInterval?,
            defaultTimeout: TimeInterval = Self.defaultTimeout,
        ) {

            self.id = requestCounter.increment()

            var urlRequest = URLRequest(url: url)

            urlRequest.httpMethod = method.rawValue
            urlRequest.httpBody = payload?.data
            urlRequest.timeoutInterval = timeout ?? defaultTimeout

            if let acceptValue = accept?.value {
                urlRequest.addValue(acceptValue, forHTTPHeaderField: "Accept")
            }

            if let contentType = payload?.contentType?.value {
                urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }

            if let headers {
                for (name, value) in headers {
                    urlRequest.setValue(value, forHTTPHeaderField: name)
                }
            }

            self.urlRequest = urlRequest
            self.logOptions = logOptions

            self.payloadSummary = payload?.summary

            var requestSummary = "[\(id)] -> \(method.rawValue) \(url.description)"

            if let payloadTypeName = payload?.typeName {
                requestSummary += " \(payloadTypeName)"
            }

            if let data = payload?.data {
                requestSummary += ", \(data.count.formatted(.byteCount(style: .memory)))"
            }

            self.requestSummary = requestSummary
        }

        init(
            urlRequest: URLRequest,
            logOptions: LogOptions? = nil,
        ) {

            self.id = requestCounter.increment()

            self.urlRequest = urlRequest
            self.logOptions = logOptions
            self.payloadSummary = nil

            var requestSummary = "[\(id)] ->"

            if let method = urlRequest.httpMethod {
                requestSummary += " \(method.uppercased())"
            }

            if let url = urlRequest.url {
                requestSummary += " \(url.description)"
            }

            if let data = urlRequest.httpBody {
                requestSummary += ", \(data.count.formatted(.byteCount(style: .memory)))"
            }

            self.requestSummary = requestSummary
        }
    }

    struct Payload: Sendable {
        let data: Data
        let contentType: ContentType?
        let typeName: String?
        let summary: String
    }
}

// MARK: - ClientResponse

extension HTTPClient {

    struct ClientResponse {

        let requestID: Int
        let requestTimestamp: Date
        let statusCode: StatusCode?
        let headers: [String: String]?
        let data: Data?

        let timestamp: Date = .init()

        init(clientRequest: ClientRequest, urlResponse: URLResponse?, data: Data?) {

            self.requestID = clientRequest.id
            self.requestTimestamp = clientRequest.timestamp
            self.data = data

            if let httpURLResponse = urlResponse as? HTTPURLResponse {
                let (statusCode, headers) = Self.extractHeaders(from: httpURLResponse)
                self.statusCode = statusCode
                self.headers = headers
            } else {
                self.statusCode = nil
                self.headers = nil
            }
        }

        private static func extractHeaders(
            from httpURLResponse: HTTPURLResponse,
        ) -> (StatusCode?, [String: String]?) {

            var headers: [String: String] = [:]

            for (key, value) in httpURLResponse.allHeaderFields {
                guard
                    let keyString = key as? String,
                    let valueString = value as? String
                else { continue }
                headers[keyString] = valueString
            }

            return (
                StatusCode(rawValue: httpURLResponse.statusCode),
                headers.isEmpty ? nil : headers,
            )
        }

        func logDescription(includeResponseBody: Bool) -> String {

            var parts = [String]()

            var forceIncludeResponseBody = false
            if let statusCode {
                parts.append("[\(requestID)] <- " + statusCode.description)
                forceIncludeResponseBody = !statusCode.isSuccess && statusCode != .notFound
            } else {
                parts.append("[\(requestID)]")
            }

            if let data {
                parts.append(data.count.formatted(.byteCount(style: .memory)))
            }

            parts.append(Date.debugDurationString(from: requestTimestamp, to: timestamp))

            var responseDescription: String?

            if forceIncludeResponseBody || includeResponseBody, let data, !data.isEmpty {
                parts.append(data.count.formatted(.byteCount(style: .memory)))
                if let text = String(data: data, encoding: .utf8) {
                    responseDescription = "\n----\n" + text + "\n-----"
                }
            }

            var description = parts.joined(separator: ", ")

            if let responseDescription {
                description.append(responseDescription)
            }

            return description
        }
    }
}

// MARK: - Internal Request Helpers

extension HTTPClient {

    func request(
        url: URL,
        method: Method,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> (Data?, HTTPURLResponse) {

        let clientRequest = ClientRequest(
            url: url,
            method: method,
            payload: .none,
            accept: .binary,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest)
    }

    func request<Output: Decodable>(
        url: URL,
        method: Method,
        data: Data?,
        outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        let payload: Payload? =
            if let data {
                Payload(
                    data: data,
                    contentType: .binary,
                    typeName: "\(Data.self)",
                    summary: data.count.formatted(.byteCount(style: .memory)))
            } else {
                nil
            }

        let clientRequest = ClientRequest(
            url: url,
            method: method,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func request<Input: Encodable>(
        url: URL,
        method: Method,
        input: Input,
        headers: [String: String]? = nil,
        timeout: TimeInterval?,
        logOptions: LogOptions? = nil,
    ) async throws -> (Data?, HTTPURLResponse) {

        let data = try jsonCoder.encode(input, userInfo: nil)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(Input.self)",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary)

        let clientRequest = ClientRequest(
            url: url,
            method: method,
            payload: payload,
            accept: .binary,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest)
    }

    func request<Input: Encodable, Output: Decodable>(
        url: URL,
        method: Method,
        input: Input,
        outputType: Output.Type,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]?,
        logOptions: LogOptions? = nil,
    ) async throws -> Output {

        let data = try jsonCoder.encode(input, userInfo: userInfo)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(Input.self)",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary,
        )

        let clientRequest = ClientRequest(
            url: url,
            method: method,
            payload: payload,
            accept: .json,
            logOptions: logOptions,
            headers: headers,
            timeout: timeout,
            defaultTimeout: defaultTimeout,
        )

        return try await request(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    func request<Output: Decodable>(
        _ clientRequest: ClientRequest,
        outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]?,
    ) async throws -> Output {

        let (data, _) = try await request(clientRequest)

        return try jsonCoder.decode(
            outputType,
            from: data,
            userInfo: userInfo,
        )
    }

    func requestWithResponse<Output: Decodable>(
        _ clientRequest: ClientRequest,
        outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]?,
    ) async throws -> Response<Output> {

        let (data, httpURLResponse) = try await request(clientRequest)

        let value = try jsonCoder.decode(
            outputType,
            from: data,
            userInfo: userInfo,
        )

        return Response(value: value, httpResponse: httpURLResponse)
    }

    func payload(for form: MultipartForm) -> Payload {
        Payload(
            data: form.data,
            contentType: ContentType.multipartForm(MultipartForm.boundary),
            typeName: "\(MultipartForm.self)",
            summary: form.summary,
        )
    }

    func payload(for form: URLEncodedForm) -> Payload {
        Payload(
            data: form.data,
            contentType: ContentType.urlEncodedForm,
            typeName: "\(URLEncodedForm.self)",
            summary: form.summary,
        )
    }

    fileprivate final class RequestCounter {

        private var value: Int = 0
        private let queue = DispatchQueue(label: "MirageCore.HTTPClient.RequestCounter")

        func increment() -> Int {
            queue.sync {
                if value == .max - 1 {
                    value = 0
                } else {
                    value += 1
                }
                return value
            }
        }

        func get() -> Int {
            queue.sync { value }
        }
    }
}
