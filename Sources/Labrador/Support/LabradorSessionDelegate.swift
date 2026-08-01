//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class LabradorSessionDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    // MARK: - Properties

    private let trustSelfSignedCertificates: Bool
    private let clock = ContinuousClock()
    private let lock = NSLock()
    private var states: [Int: DownloadState] = [:]

    // MARK: - Init

    init(trustSelfSignedCertificates: Bool) {
        self.trustSelfSignedCertificates = trustSelfSignedCertificates
    }

    // MARK: - Registration

    struct DownloadState {
        let continuation: AsyncStream<Labrador.FileDownloadEvent>.Continuation
        let progressThrottleInterval: TimeInterval
        var lastReportedBytes: Int64 = 0
        var lastReportedProgress: ContinuousClock.Instant
    }

    func register(
        _ continuation: AsyncStream<Labrador.FileDownloadEvent>.Continuation,
        progressThrottleInterval: TimeInterval,
        for taskID: Int,
    ) {
        lock.lock()
        defer { lock.unlock() }
        states[taskID] = DownloadState(
            continuation: continuation,
            progressThrottleInterval: progressThrottleInterval,
            lastReportedProgress: clock.now
        )
    }

    @discardableResult
    func unregister(for taskID: Int) -> AsyncStream<Labrador.FileDownloadEvent>.Continuation? {
        lock.lock()
        defer { lock.unlock() }
        return states.removeValue(forKey: taskID)?.continuation
    }

    // MARK: - URLSessionDelegate (TLS)

    #if canImport(Security)
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        handleChallenge(challenge)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        handleChallenge(challenge)
    }

    private func handleChallenge(
        _ challenge: URLAuthenticationChallenge,
    ) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard
            trustSelfSignedCertificates,
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            return (.performDefaultHandling, nil)
        }
        return (.useCredential, URLCredential(trust: serverTrust))
    }
    #endif

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWrittenThisCall: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        let taskID = downloadTask.taskIdentifier

        lock.lock()
        guard var state = states[taskID] else {
            lock.unlock()
            return
        }
        let now = clock.now
        let elapsed = Self.seconds(from: state.lastReportedProgress.duration(to: now))
        guard elapsed >= state.progressThrottleInterval else {
            lock.unlock()
            return
        }
        let lastBytes = state.lastReportedBytes
        state.lastReportedProgress = now
        state.lastReportedBytes = totalBytesWritten
        states[taskID] = state
        let continuation = state.continuation
        lock.unlock()

        let speed: Double? = elapsed > 0 ? Double(totalBytesWritten - lastBytes) / elapsed : nil
        let totalBytes: Int64? = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
        continuation.yield(.progress(bytesWritten: totalBytesWritten, totalBytes: totalBytes, speed: speed))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL,
    ) {
        lock.lock()
        let state = states[downloadTask.taskIdentifier]
        lock.unlock()

        guard let state else { return }

        let totalWritten = downloadTask.countOfBytesReceived
        let totalExpected = downloadTask.countOfBytesExpectedToReceive
        state.continuation.yield(
            .progress(
                bytesWritten: totalWritten,
                totalBytes: totalExpected > 0 ? totalExpected : nil,
                speed: nil,
            )
        )

        do {
            var stableURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            let ext = location.pathExtension
            if !ext.isEmpty {
                stableURL.appendPathExtension(ext)
            }
            try FileManager.default.moveItem(at: location, to: stableURL)
            state.continuation.yield(.completed(tempFileURL: stableURL))
        } catch {
            state.continuation.yield(.failed(error))
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

    // MARK: - Helpers

    private static func seconds(from duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
