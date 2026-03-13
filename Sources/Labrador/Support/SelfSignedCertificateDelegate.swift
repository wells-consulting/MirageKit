//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(Security)

import Foundation

/// A URLSession delegate that accepts self-signed TLS certificates.
///
/// When a server presents a certificate that fails the default trust
/// evaluation (e.g. self-signed or bound to an IP address), this delegate
/// creates a credential from the server's certificate and allows the
/// connection to proceed.
///
/// Use this only for servers the user has explicitly opted into trusting.
///
/// ## Usage
///
/// ```swift
/// let delegate = SelfSignedCertificateDelegate()
/// let session = URLSession(
///     configuration: .default,
///     delegate: delegate,
///     delegateQueue: nil,
/// )
/// ```
public final class SelfSignedCertificateDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate,
    Sendable
{

    // MARK: - URLSessionDelegate

    // Session-level challenge (called for connection-level TLS handshakes)
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        handleChallenge(challenge)
    }

    // MARK: - URLSessionTaskDelegate

    // Task-level challenge (called when URLSession.data(for:) triggers TLS)
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        handleChallenge(challenge)
    }

    // MARK: - Private

    private func handleChallenge(
        _ challenge: URLAuthenticationChallenge,
    ) -> (URLSession.AuthChallengeDisposition, URLCredential?) {

        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            return (.performDefaultHandling, nil)
        }

        let credential = URLCredential(trust: serverTrust)
        return (.useCredential, credential)
    }
}

#endif
