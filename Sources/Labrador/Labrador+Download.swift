//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Download

public extension Labrador {

    enum DownloadEvent: Sendable {
        case progress(bytesReceived: Int64, totalBytes: Int64?)
        case completed(Data)
        case failed(any Error)
    }

    func download(
        _ url: URL,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<DownloadEvent> {

        let urlSession = urlSession
        let additionalHeaders = additionalHeaders

        return AsyncStream { continuation in
            let task = Task {
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = Method.get.rawValue
                if let timeout {
                    urlRequest.timeoutInterval = timeout
                }

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

    // MARK: - File Download

    enum FileDownloadEvent: Sendable {
        case progress(bytesWritten: Int64, totalBytes: Int64?)
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
    func downloadToFile(
        _ request: URLRequest,
        resumeData: Data? = nil,
        trustSelfSignedCertificates: Bool = false,
        httpMaximumConnectionsPerHost: Int? = nil,
        logContext: String? = nil,
    ) -> AsyncStream<FileDownloadEvent> {

        let coordinator = FileDownloadCoordinator(trustSelfSignedCertificates: trustSelfSignedCertificates)

        let config = URLSessionConfiguration.default
        if let httpMaximumConnectionsPerHost {
            config.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        }

        let session = URLSession(
            configuration: config,
            delegate: coordinator,
            delegateQueue: nil,
        )

        return AsyncStream { continuation in
            let downloadTask: URLSessionDownloadTask
            if let resumeData {
                downloadTask = session.downloadTask(withResumeData: resumeData)
            } else {
                downloadTask = session.downloadTask(with: request)
            }

            coordinator.register(continuation, for: downloadTask.taskIdentifier)
            downloadTask.resume()

            continuation.onTermination = { [session, coordinator, downloadTask, continuation] reason in
                switch reason {
                case .cancelled:
                    // Remove the continuation before cancelling so the
                    // didCompleteWithError delegate callback (which fires with
                    // URLError.cancelled) does not double-finish the stream.
                    coordinator.unregister(for: downloadTask.taskIdentifier)
                    downloadTask.cancel(byProducingResumeData: { [continuation, session] data in
                        continuation.yield(.cancelled(resumeData: data))
                        continuation.finish()
                        session.invalidateAndCancel()
                    })
                case .finished:
                    session.finishTasksAndInvalidate()
                @unknown default:
                    session.invalidateAndCancel()
                }
            }
        }
    }
}

// MARK: - FileDownloadCoordinator

private final class FileDownloadCoordinator: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    private static let progressInterval: Int64 = 65_536

    private let trustSelfSignedCertificates: Bool
    private let lock = NSLock()
    private var continuations: [Int: AsyncStream<Labrador.FileDownloadEvent>.Continuation] = [:]
    private var lastReportedBytes: [Int: Int64] = [:]

    init(trustSelfSignedCertificates: Bool) {
        self.trustSelfSignedCertificates = trustSelfSignedCertificates
    }

    func register(
        _ continuation: AsyncStream<Labrador.FileDownloadEvent>.Continuation,
        for taskID: Int,
    ) {
        lock.lock()
        defer { lock.unlock() }
        continuations[taskID] = continuation
        lastReportedBytes[taskID] = 0
    }

    @discardableResult
    func unregister(for taskID: Int) -> AsyncStream<Labrador.FileDownloadEvent>.Continuation? {
        lock.lock()
        defer { lock.unlock() }
        lastReportedBytes.removeValue(forKey: taskID)
        return continuations.removeValue(forKey: taskID)
    }

    // MARK: URLSessionDelegate

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void,
    ) {
        if trustSelfSignedCertificates,
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust
        {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWrittenThisCall: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        lock.lock()
        let continuation = continuations[downloadTask.taskIdentifier]
        let last = lastReportedBytes[downloadTask.taskIdentifier] ?? 0
        let shouldReport = totalBytesWritten - last >= Self.progressInterval
        if shouldReport {
            lastReportedBytes[downloadTask.taskIdentifier] = totalBytesWritten
        }
        lock.unlock()

        guard shouldReport, let continuation else { return }

        let totalBytes: Int64? = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
        continuation.yield(.progress(bytesWritten: totalBytesWritten, totalBytes: totalBytes))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL,
    ) {
        lock.lock()
        let continuation = continuations[downloadTask.taskIdentifier]
        lock.unlock()

        guard let continuation else { return }

        // Emit a final progress snapshot.
        let totalWritten = downloadTask.countOfBytesReceived
        let totalExpected = downloadTask.countOfBytesExpectedToReceive
        continuation.yield(.progress(
            bytesWritten: totalWritten,
            totalBytes: totalExpected > 0 ? totalExpected : nil,
        ))

        // URLSession reclaims `location` once this callback returns, so we move
        // the file to a stable temp URL here — synchronously, before returning —
        // so the URL we hand to the consumer via .completed remains valid.
        do {
            var stableURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            let ext = location.pathExtension
            if !ext.isEmpty {
                stableURL.appendPathExtension(ext)
            }
            try FileManager.default.moveItem(at: location, to: stableURL)
            continuation.yield(.completed(tempFileURL: stableURL))
        } catch {
            continuation.yield(.failed(error))
        }
        // continuation.finish() is NOT called here; URLSession calls
        // urlSession(_:task:didCompleteWithError:) immediately after this
        // method returns, and that is where we close the stream.
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?,
    ) {
        let continuation = unregister(for: task.taskIdentifier)

        if let error, (error as? URLError)?.code != .cancelled {
            continuation?.yield(.failed(error))
        }
        continuation?.finish()
    }
}
