//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Upload

public extension Labrador {

    enum UploadEvent: Sendable {
        case progress(bytesSent: Int64, totalBytes: Int64?)
        case completed(Data)
        case failed(any Error)
    }

    func upload(
        _ url: URL,
        data body: Data,
        method: Method = .post,
        contentType: ContentType = .binary,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
    ) -> AsyncStream<UploadEvent> {

        let urlSession = urlSession
        let additionalHeaders = additionalHeaders
        let effectiveTimeout = timeout ?? defaultTimeout

        return AsyncStream { continuation in
            let task = Task {
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = method.rawValue
                urlRequest.timeoutInterval = effectiveTimeout
                urlRequest.setValue(contentType.value, forHTTPHeaderField: "Content-Type")

                for (name, value) in additionalHeaders {
                    urlRequest.setValue(value, forHTTPHeaderField: name)
                }

                if let headers {
                    for (name, value) in headers {
                        urlRequest.setValue(value, forHTTPHeaderField: name)
                    }
                }

                let delegate = UploadProgressDelegate(continuation: continuation)

                do {
                    let (responseData, _) = try await urlSession.upload(
                        for: urlRequest,
                        from: body,
                        delegate: delegate,
                    )

                    continuation.yield(.completed(responseData))
                } catch is CancellationError {
                    // Stream was cancelled; nothing to yield
                } catch {
                    continuation.yield(.failed(error))
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func upload(
        _ url: URL,
        form: MultipartForm,
        method: Method = .post,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
    ) -> AsyncStream<UploadEvent> {
        upload(
            url,
            data: form.data,
            method: method,
            contentType: .multipartForm(MultipartForm.boundary),
            headers: headers,
            timeout: timeout,
        )
    }

    func upload(
        _ url: URL,
        form: URLEncodedForm,
        method: Method = .post,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
    ) -> AsyncStream<UploadEvent> {
        upload(
            url,
            data: form.data,
            method: method,
            contentType: .urlEncodedForm,
            headers: headers,
            timeout: timeout,
        )
    }
}

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {

    private let continuation: AsyncStream<Labrador.UploadEvent>.Continuation

    init(continuation: AsyncStream<Labrador.UploadEvent>.Continuation) {
        self.continuation = continuation
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64,
    ) {
        let total: Int64? = totalBytesExpectedToSend != NSURLSessionTransferSizeUnknown
            ? totalBytesExpectedToSend
            : nil

        continuation.yield(.progress(bytesSent: totalBytesSent, totalBytes: total))
    }
}
