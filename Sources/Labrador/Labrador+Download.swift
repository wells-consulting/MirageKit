//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Download

extension Labrador {

    public enum DownloadEvent: Sendable {
        case progress(bytesReceived: Int64, totalBytes: Int64?)
        case completed(Data)
        case failed(any Error)
    }

    public func downloadInMemory(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<DownloadEvent> {

        let clientRequest = ClientRequest(
            url: url,
            method: .get,
            payload: nil,
            headers: headers,
            timeout: timeout
        )

        log(clientRequest)

        let urlRequest = urlRequestWithUpdatedHeaders(from: clientRequest)

        let urlSession = urlSession

        return AsyncStream { continuation in
            let task = Task {
                do {
                    let (data, urlResponse) = try await urlSession.data(for: urlRequest)

                    let totalBytes: Int64? = {
                        let expected = urlResponse.expectedContentLength
                        return expected != -1 ? expected : nil
                    }()

                    let bytesReceived = Int64(data.count)

                    continuation.yield(.progress(bytesReceived: bytesReceived, totalBytes: totalBytes))
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

    // MARK: - File Download

    public enum FileDownloadEvent: Sendable {
        case progress(bytesWritten: Int64, totalBytes: Int64?, speed: Double?)
        case completed(tempFileURL: URL)
        case cancelled(resumeData: Data?)
        case failed(any Error)
    }

    /// Downloads a resource directly to disk via `URLSessionDownloadTask`.
    ///
    /// Use this instead of ``download(_:headers:timeout:logContext:)`` for large files
    /// (e.g. video) where buffering the entire response in memory is not acceptable.
    ///
    /// The caller is responsible for moving `tempFileURL` to its final destination
    /// when handling the `.completed` event — the URL is stable across the event
    /// loop but will be cleaned up on the next system temp-directory sweep.
    ///
    /// To pause and resume a download, cancel the consuming `Task`. The
    /// `.cancelled(resumeData:)` event carries opaque resume data (may be `nil`
    /// for very short downloads) that can be passed back via `resumeData:` on the
    /// next call.
    public func downloadToFile(
        _ request: URLRequest,
        resumeData: Data? = nil,
        timeout: TimeInterval? = nil,
        progressThrottleInterval: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<FileDownloadEvent> {

        let clientRequest = ClientRequest(
            urlRequest: request,
            logContext: logContext,
        )

        log(clientRequest)

        let sessionDelegate = sessionDelegate
        let session = urlSession
        let throttleInterval = progressThrottleInterval ?? 1.0

        return AsyncStream { continuation in
            let downloadTask: URLSessionDownloadTask
            if let resumeData {
                downloadTask = session.downloadTask(withResumeData: resumeData)
            } else {
                downloadTask = session.downloadTask(with: request)
            }

            sessionDelegate?.register(continuation, progressThrottleInterval: throttleInterval, for: downloadTask.taskIdentifier)
            downloadTask.resume()

            continuation.onTermination = { [sessionDelegate, downloadTask, continuation] reason in
                switch reason {
                case .cancelled:
                    sessionDelegate?.unregister(for: downloadTask.taskIdentifier)
                    downloadTask.cancel(byProducingResumeData: { data in
                        continuation.yield(.cancelled(resumeData: data))
                        continuation.finish()
                    })
                case .finished:
                    break
                @unknown default:
                    downloadTask.cancel()
                }
            }
        }
    }
}
