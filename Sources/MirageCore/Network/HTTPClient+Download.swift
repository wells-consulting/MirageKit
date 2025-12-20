//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Download

public extension HTTPClient {

    enum DownloadEvent: Sendable {
        case progress(bytesReceived: Int64, totalBytes: Int64?)
        case completed(Data)
        case failed(any Error)
    }

    func download(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
    ) -> AsyncStream<DownloadEvent> {

        let urlSession = urlSession
        let additionalHeaders = additionalHeaders
        let effectiveTimeout = timeout ?? defaultTimeout

        return AsyncStream { continuation in
            let task = Task {
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = Method.get.rawValue
                urlRequest.timeoutInterval = effectiveTimeout

                for (name, value) in additionalHeaders {
                    urlRequest.setValue(value, forHTTPHeaderField: name)
                }

                if let headers {
                    for (name, value) in headers {
                        urlRequest.setValue(value, forHTTPHeaderField: name)
                    }
                }

                do {
                    let (asyncBytes, urlResponse) = try await urlSession.bytes(for: urlRequest)

                    let totalBytes: Int64? = {
                        let expected = urlResponse.expectedContentLength
                        return expected != -1 ? expected : nil
                    }()

                    var data = Data()
                    if let totalBytes {
                        data.reserveCapacity(Int(totalBytes))
                    }

                    var bytesReceived: Int64 = 0
                    let chunkSize: Int64 = 65536

                    for try await byte in asyncBytes {

                        try Task.checkCancellation()
                        data.append(byte)
                        bytesReceived += 1

                        if bytesReceived % chunkSize == 0 {
                            continuation.yield(
                                .progress(bytesReceived: bytesReceived, totalBytes: totalBytes),
                            )
                        }
                    }

                    // Emit final progress to ensure the caller sees 100%
                    continuation.yield(
                        .progress(bytesReceived: bytesReceived, totalBytes: totalBytes),
                    )

                    continuation.yield(.completed(data))

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
}
