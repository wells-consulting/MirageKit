//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor HTTPClient {

    private let urlSession: URLSession
    private var additionalHeaders: [String: String] = [:]
    private let logOptions: LogOptions
    private let jsonCoder: JSONCoder
    private let log: Log

    // MARK: Initializer

    public struct LogOptions: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let request = LogOptions(rawValue: 1 << 1)
        public static let requestBody = LogOptions(rawValue: 1 << 2)
        public static let response = LogOptions(rawValue: 1 << 3)
        public static let responseBody = LogOptions(rawValue: 1 << 4)

        public static let logAll: LogOptions = [
            .request, .requestBody, .response, .responseBody
        ]
    }

    public struct Configuration: Sendable {

        let jsonCoder: JSONCoder
        let logOptions: LogOptions
        let headers: [String: String]
        let oAuthToken: OAuthToken?

        public init(
            headers: [String: String] = [:],
            oAuthToken: OAuthToken? = nil,
            jsonCoder: JSONCoder? = nil,
            logOptions: LogOptions = []
        ) {
            self.headers = headers
            self.oAuthToken = oAuthToken
            self.jsonCoder = jsonCoder ?? .shared
            self.logOptions = logOptions
        }
    }

    public init(configuration: Configuration = .init()) {

        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpAdditionalHeaders = configuration.headers
        urlSessionConfiguration.timeoutIntervalForRequest = ClientRequest.defaultTimeout
        urlSessionConfiguration.httpCookieStorage = HTTPCookieStorage.shared

        self.urlSession = URLSession(configuration: urlSessionConfiguration)
        self.logOptions = configuration.logOptions
        self.jsonCoder = configuration.jsonCoder

        if let accessToken = configuration.oAuthToken?.accessToken {
            additionalHeaders["Authorization"] = "Bearer \(accessToken)"
        }

        self.log = Log(subsystem: Bundle.appName, category: #fileID)
    }

    // MARK: - Dispatch

    private nonisolated(unsafe) static let requestCounter = RequestCounter()

    private func request(
        _ clientRequest: ClientRequest,
    ) async throws -> (Data?, HTTPURLResponse) {

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

        let data: Data?
        let urlResponse: URLResponse

        do {
            let (_data, _urlResponse) = try await urlSession.data(for: urlRequest)
            data = _data
            urlResponse = _urlResponse
        } catch {
            throw HTTPError(
                refcode: clientRequest.refcode,
                underlyingErrors: [error],
                clientRequest: clientRequest)
        }

        let httpResponse = ClientResponse(
            clientRequest: clientRequest,
            urlResponse: urlResponse,
            data: data
        )

        if shouldLogResponse {
            let message = httpResponse.logDescription(includeResponseBody: shouldLogResponseBody)
            log.debug(message)
        }

        // Unrecoverable error: response must be an HTTPURLResponse

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            throw HTTPError(
                refcode: clientRequest.refcode,
                clarification: "Network request failed.",
                clientRequest: clientRequest,
                responseData: data)
        }

        // Unrecoverable error: status code must be known

        guard let statusCode = StatusCode(rawValue: httpURLResponse.statusCode) else {
            throw HTTPError(
                refcode: clientRequest.refcode,
                clarification: "Network request failed.",
                clientRequest: clientRequest,
                httpURLResponse: httpURLResponse,
                responseData: data)
        }

        // Failure is not an option

        guard statusCode.isSuccess else {
            throw HTTPError(
                refcode: clientRequest.refcode,
                clarification: "Network request failed.",
                clientRequest: clientRequest,
                httpURLResponse: httpURLResponse,
                responseData: data)
        }

        return (data, httpURLResponse)
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
        setHeader(name: name, value: nil)
    }

    // MARK: - Helpers

    public func setAuthToken(_ authToken: OAuthToken?) {
        if let accessToken = authToken?.accessToken {
            setHeader(name: "Authorization", value: "Bearer \(accessToken)")
        } else {
            removeHeader("Authorization")
        }
    }
}

// MARK: - Content Type

extension HTTPClient {

    enum ContentType: Sendable {

        case json
        case multipartForm(String)
        case urlEncodedForm
        case text
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
            case _ where text.hasPrefix("/multipart/form-data; boundary="):
                let matches = text.matches(of: /multipart\/form-data; boundary=(.*)/)
                if matches.count == 2 {
                    self = .multipartForm(String(text[matches[1].range]))
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

// MARK: ClientRequest

extension HTTPClient {

    struct ClientRequest {

        let id: Int
        let refcode: String
        let urlRequest: URLRequest
        let requestSummary: String
        let payloadSummary: String?
        let timestamp: Date = .init()
        let logOptions: LogOptions?

        static let defaultTimeout: TimeInterval = 30.0 * 1000.0 // 30s

        init(
            refcode: String,
            urlRequest: URLRequest,
            payload: Payload?,
            logOptions: LogOptions? = nil
        ) {
            self.refcode = refcode
            self.id = requestCounter.increment()

            self.urlRequest = urlRequest
            self.logOptions = logOptions
            self.payloadSummary = payload?.summary

            var summary = "[\(id)] -> " + (urlRequest.httpMethod ?? "NO_METHOD")

            if let url = urlRequest.url {
                summary += " " + url.description
            }

            if let typeName = payload?.typeName {
                summary += " " + typeName
            }

            if let data = urlRequest.httpBody {
                summary += ", \(data.count.formatted(.byteCount(style: .memory)))"
            }

            self.requestSummary = summary
        }

        init(
            refcode: String,
            url: URL,
            method: Method,
            payload: Payload,
            accept: ContentType,
            logOptions: LogOptions? = nil,
            headers: [String: String]? = nil,
            timeout: TimeInterval? = nil
        ) {

            var urlRequest = URLRequest(url: url)

            urlRequest.httpMethod = method.rawValue
            urlRequest.timeoutInterval = timeout ?? Self.defaultTimeout

            urlRequest.addValue(accept.value, forHTTPHeaderField: "Accept")

            if let contentType = payload.contentType {
                urlRequest.addValue(contentType.value, forHTTPHeaderField: "Content-Type")
            }

            if let headers {
                urlRequest.allHTTPHeaderFields = headers
            }

            self.init(
                refcode: refcode,
                urlRequest: urlRequest,
                payload: payload,
                logOptions: logOptions)
        }
    }

    public enum Method: String, Sendable {
        case delete = "DELETE"
        case get = "GET"
        case patch = "PATCH"
        case post = "POST"
        case put = "PUT"
    }

    struct Payload: Sendable {

        let data: Data
        let contentType: ContentType?
        let typeName: String?
        let summary: String

        static let none = Payload(
            data: Data(capacity: 0),
            contentType: nil,
            typeName: nil,
            summary: "nil")
    }
}

// MARK: ClientResponse

extension HTTPClient {

    struct ClientResponse {

        let refcode: String
        let requestID: Int
        let requestTimestamp: Date
        let statusCode: StatusCode?
        let headers: [String: String]?
        let data: Data?

        let timestamp: Date = .init()

        init(clientRequest: ClientRequest, urlResponse: URLResponse?, data: Data?) {

            self.refcode = clientRequest.refcode
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
            from httpURLResponse: HTTPURLResponse
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
                headers.isEmpty ? nil : headers
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

    public enum StatusCode: Int, Codable, CustomStringConvertible, Sendable {

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

        public var isSuccess: Bool { rawValue >= 200 && rawValue < 299 }
        public var isClientError: Bool { rawValue >= 400 && rawValue < 499 }
        public var isServerError: Bool { rawValue >= 500 && rawValue < 599 }

        public var description: String {
            switch self {
            // 10x
            case .continue:
                "100 Continue"
            case .switchingProtocols:
                "101 Switching Protocols"
            case .processing:
                "102 Processing"
            // 20x
            case .ok:
                "200 OK"
            case .created:
                "201 Created"
            case .accepted:
                "202 Accepted"
            case .nonAuthoritativeInformation:
                "203 Non-Authoritative Information"
            case .noContent:
                "204 No Content"
            case .resetContent:
                "205 Reset Content"
            case .partialContent:
                "206 Partial Content"
            case .multiStatus:
                "207 Mult-status (WebDAV)"
            case .imUsed:
                "226 IM Used"
            case .alreadyReported:
                "208 Already Reported (WebDAV)"
            // 30x
            case .multipleChoices:
                "300 Multiple Choices"
            case .movedPermanently:
                "301 Moved Permantley"
            case .found:
                "302 Found"
            case .seeOther:
                "303 See Other"
            case .notModified:
                "304 Not Modified"
            case .useProxy:
                "305 Use Proxy"
            case .switchProxy:
                "306 Switch Proxy"
            case .temporaryRedirect:
                "307 Temporary Redirect"
            case .permanentRedirect:
                "308 Permanent Redirect"
            // 40x
            case .badRequest:
                "400 Bad Request"
            case .unauthorized:
                "401 Unauthorized"
            case .paymentRequired:
                "402 Payment Required"
            case .forbidden:
                "403 Forbidden"
            case .notFound:
                "404 Not Found"
            case .methodNotAllowed:
                "405 Method Not Allowed"
            case .notAcceptable:
                "406 Not Acceptable"
            case .proxyAuthenticationRequired:
                "407 Proxy Authenticion Required"
            case .requestTimeout:
                "408 Request Timeout"
            case .conflict:
                "409 Conflict"
            case .gone:
                "410 Gone"
            case .lengthRequired:
                "411 Length Required"
            case .preconditionFailed:
                "412 Precondition Failed"
            case .payloadTooLarge:
                "413 Payload Too Large"
            case .uriTooLong:
                "414 URI Too Long"
            case .unsupportedMediaType:
                "415 Unsuported Media Type"
            case .rangeNotSatisfiable:
                "416 Range Not Satisfiable"
            case .expectationFailed:
                "417 Expectation Failed"
            case .imATeapot:
                "418 I'm a Teapot"
            case .misdirectedRequest:
                "421 Misdirected Request"
            case .unprocessableEntity:
                "422 Unprocessable Entity (WebDAV)"
            case .locked:
                "423 Locked (WebDAV)"
            case .failedDependency:
                "424 Failed Dependency (WebDAV)"
            case .upgradeRequired:
                "426 Upgrade Required"
            case .preconditionRequired:
                "428 Precondition Required"
            case .tooManyRequests:
                "429 Too Many Requests"
            case .requestHeaderFieldsTooLarge:
                "431 Request Header Fields Too Large"
            case .unavailableForLegalReasons:
                "451 Unavailable For Legal Reasons"
            // 50x
            case .internalServerError:
                "500 Internal Server Error"
            case .notImplemented:
                "501 Not Implemented"
            case .badGateway:
                "502 Bad Gateway"
            case .serviceUnavailable:
                "503 Service Unavailable"
            case .gatewayTimeout:
                "504 Gateway Timeout"
            case .httpVersionNotSupported:
                "505 HTTP Version Not Supported"
            case .variantAlsoNegotiates:
                "506 Variant Also Negotiates"
            case .insufficientStorage:
                "507 Insufficient Storage (WebDAV)"
            case .loopDetected:
                "508 Loop Dected (WebDAV)"
            case .notExtended:
                "510 Not Extended"
            case .networkAuthenticationRequired:
                "511 Network Authentication Required"
            }
        }
    }
}

// MARK: - Simple Request

public extension HTTPClient {

    func data(
        for urlRequest: URLRequest,
        refcode: String,
    ) async throws -> (Data?, HTTPURLResponse) {

        try await request(.init(
            refcode: refcode,
            urlRequest: urlRequest,
            payload: nil))
    }
}

// MARK: - GET

public extension HTTPClient {

    func get(
        _ url: URL,
        headers: [String: String]? = nil,
        refcode: String,
    ) async throws -> Data? {

        let (data, _) = try await request(
            refcode: refcode,
            url: url,
            method: .get,
            headers: headers)

        return data
    }

    func get(
        _ urlRequest: URLRequest,
        refcode: String,
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        let (data, _) = try await request(
            refcode: refcode,
            url: url,
            method: .get,
            headers: urlRequest.allHTTPHeaderFields)

        return data
    }

    func get<Output: Decodable>(
        _ url: URL,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String,
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .get,
            data: nil,
            outputType: Output.self,
            headers: headers,
            userInfo: userInfo)
    }

    func get<Output: Decodable>(
        _ urlRequest: URLRequest,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String,
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .get,
            data: nil,
            outputType: Output.self,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }
}

// MARK: - POST

public extension HTTPClient {

    func post(
        _ url: URL,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .post,
            headers: headers).0
    }

    func post(
        _ urlRequest: URLRequest,
        refcode: String,
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .post,
            headers: urlRequest.allHTTPHeaderFields ?? [:]).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        data: Data,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String,
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .post,
            data: data,
            outputType: outputType,
            headers: headers,
            userInfo: userInfo)
    }

    func post<Output: Decodable>(
        _ urlRequest: URLRequest,
        data: Data,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .post,
            data: data,
            outputType: outputType,
            headers: urlRequest.allHTTPHeaderFields ?? [:],
            userInfo: userInfo)
    }

    func post(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        refcode: String,
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .post,
            input: input,
            headers: headers).0
    }

    func post(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .post,
            input: input,
            headers: urlRequest.allHTTPHeaderFields ?? [:]).0
    }

    func post<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String,
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .post,
            input: input,
            outputType: outputType,
            headers: headers,
            userInfo: userInfo)
    }

    func post<Output: Decodable>(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .post,
            input: input,
            outputType: outputType,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }

    // MARK: MultipartForm

    private func payload(for form: MultipartForm) -> Payload {

        Payload(
            data: form.data,
            contentType: ContentType.multipartForm(MultipartForm.boundary),
            typeName: "\(MultipartForm.self)",
            summary: form.summary)
    }

    func post(
        _ url: URL,
        form: MultipartForm,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers)

        return try await request(clientRequest).0
    }

    func post(
        _ urlRequest: URLRequest,
        form: MultipartForm,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await post(
            url,
            form: form,
            headers: urlRequest.allHTTPHeaderFields,
            refcode: refcode)
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: MultipartForm,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers)

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo)
    }

    // MARK: URLEncodedForm

    private func payload(for form: URLEncodedForm) -> Payload {

        Payload(
            data: form.data,
            contentType: ContentType.urlEncodedForm,
            typeName: "\(URLEncodedForm.self)",
            summary: form.summary)
    }

    func post(
        _ url: URL,
        form: URLEncodedForm,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            headers: headers)

        return try await request(clientRequest).0
    }

    func post(
        _ urlRequest: URLRequest,
        form: URLEncodedForm,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await post(
            url,
            form: form,
            headers: urlRequest.allHTTPHeaderFields,
            refcode: refcode)
    }

    func post<Output: Decodable>(
        _ url: URL,
        form: URLEncodedForm,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        let payload = payload(for: form)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers)

        return try await request(
            clientRequest,
            outputType: outputType,
            userInfo: userInfo)
    }

    func post<Output: Decodable>(
        _ urlRequest: URLRequest,
        form: URLEncodedForm,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await post(
            url,
            form: form,
            decoding: outputType,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo,
            refcode: refcode)
    }
}

// MARK: - PUT

public extension HTTPClient {

    func put(
        _ url: URL,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .put,
            headers: headers).0
    }

    func put(
        _ urlRequest: URLRequest,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .put,
            headers: urlRequest.allHTTPHeaderFields).0
    }

    func put<Output: Decodable>(
        _ url: URL,
        data: Data,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .put,
            data: data,
            outputType: outputType,
            headers: headers,
            userInfo: userInfo)
    }

    func put<Output: Decodable>(
        _ urlRequest: URLRequest,
        data: Data,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .put,
            data: data,
            outputType: outputType,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }

    func put(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .put,
            input: input,
            headers: headers).0
    }

    func put(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(
                refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .put,
            input: input,
            headers: urlRequest.allHTTPHeaderFields).0
    }

    func put<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .put,
            input: input,
            outputType: Output.self,
            headers: headers,
            userInfo: userInfo)
    }

    func put<Output: Decodable>(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .put,
            input: input,
            outputType: Output.self,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }
}

// MARK: - DELETE

public extension HTTPClient {

    func delete(
        _ url: URL,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            headers: headers).0
    }

    func delete(
        _ urlRequest: URLRequest,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            headers: urlRequest.allHTTPHeaderFields).0
    }

    func delete<Output: Decodable>(
        _ url: URL,
        data: Data,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            data: data,
            outputType: outputType,
            headers: headers,
            userInfo: userInfo)
    }

    func delete<Output: Decodable>(
        _ urlRequest: URLRequest,
        data: Data,
        decoding outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            data: data,
            outputType: outputType,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }

    func delete(
        _ url: URL,
        payload input: some Encodable,
        headers: [String: String]? = nil,
        refcode: String
    ) async throws -> Data? {

        try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            input: input,
            headers: headers).0
    }

    func delete(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        refcode: String
    ) async throws -> Data? {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            input: input,
            headers: urlRequest.allHTTPHeaderFields).0
    }

    func delete<Output: Decodable>(
        _ url: URL,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String],
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            input: input,
            outputType: Output.self,
            headers: headers,
            userInfo: userInfo)
    }

    func delete<Output: Decodable>(
        _ urlRequest: URLRequest,
        payload input: some Encodable,
        decoding outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil,
        refcode: String
    ) async throws -> Output {

        guard let url = urlRequest.url else {
            throw HTTPError.missingURL(refcode: refcode)
        }

        return try await request(
            refcode: refcode,
            url: url,
            method: .delete,
            input: input,
            outputType: Output.self,
            headers: urlRequest.allHTTPHeaderFields,
            userInfo: userInfo)
    }
}

// MARK: - Private Implementation

extension HTTPClient {

    private func request(
        refcode: String,
        url: URL,
        method: Method,
        headers: [String: String]? = nil
    ) async throws -> (Data?, HTTPURLResponse) {

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: method,
            payload: .none,
            accept: .binary,
            headers: headers)

        return try await request(clientRequest)
    }

    private func request<Output: Decodable>(
        refcode: String,
        url: URL,
        method: Method,
        data: Data?,
        outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]? = nil
    ) async throws -> Output {

        let payload =
            if let data {
                Payload(
                    data: data,
                    contentType: .binary,
                    typeName: "\(Data.self)",
                    summary: data.count.formatted(.byteCount(style: .memory)))
            } else {
                Payload.none
            }

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: method,
            payload: payload,
            accept: .json,
            headers: headers)

        return try await request(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    private func request<Input: Encodable>(
        refcode: String,
        url: URL,
        method: Method,
        input: Input,
        headers: [String: String]? = nil
    ) async throws -> (Data?, HTTPURLResponse) {

        let data = try jsonCoder.encode(input, userInfo: nil, refcode: refcode)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(Input.self)",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: method,
            payload: payload,
            accept: .binary)

        return try await request(clientRequest)
    }

    private func request<Input: Encodable, Output: Decodable>( // swiftlint:disable:this function_parameter_count
        refcode: String,
        url: URL,
        method: Method,
        input: Input,
        outputType: Output.Type,
        headers: [String: String]? = nil,
        userInfo: [CodingUserInfoKey: any Sendable]?
    ) async throws -> Output {

        let data = try jsonCoder.encode(input, userInfo: userInfo, refcode: refcode)

        let payload = Payload(
            data: data,
            contentType: .json,
            typeName: "\(Input.self)",
            summary: ((input as? (any SummaryProviding))?.summary) ?? data.summary)

        let clientRequest = ClientRequest(
            refcode: refcode,
            url: url,
            method: .put,
            payload: payload,
            accept: .json)

        return try await request(clientRequest, outputType: outputType, userInfo: userInfo)
    }

    private func request<Output: Decodable>(
        _ clientRequest: ClientRequest,
        outputType: Output.Type,
        userInfo: [CodingUserInfoKey: any Sendable]?
    ) async throws -> Output {

        let (data, httpURLResponse) = try await request(clientRequest)

        guard let data else {
            throw HTTPError(
                refcode: clientRequest.refcode,
                clarification: "Network request failed.",
                clientRequest: clientRequest,
                httpURLResponse: httpURLResponse,
                responseData: data)
        }

        return try jsonCoder.decode(
            outputType,
            from: data,
            userInfo: userInfo,
            refcode: clientRequest.refcode)
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

// MARK: - Extensions

public extension HTTPURLResponse {
    var httpClientStatusCode: HTTPClient.StatusCode? {
        .init(rawValue: statusCode)
    }
}
