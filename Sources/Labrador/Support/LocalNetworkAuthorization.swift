//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

// Preflight check for iOS Local Network permission. On first launch the
// system shows a permission dialog when the app touches the local network.
// If we try to connect to a server before the user taps "Allow", the
// connection fails. This helper triggers the dialog and waits for the
// user's response before returning.
//
// Technique from Nonstrict (https://nonstrict.eu/blog/2024/request-and-check-for-local-network-permission/)
// Uses NWBrowser + NWListener to discover each other on a private Bonjour
// service type, which triggers the Local Network permission prompt.
//
// Requires "_preflight_check._tcp" in Info.plist NSBonjourServices.

#if os(iOS)

import Foundation
import Network

private let log = Timber(category: "LocalNetworkAuth")
private let serviceType = "_preflight_check._tcp"

/// Checks whether Local Network permission has been granted. If the
/// authorization state isn't yet determined, this triggers the system
/// permission dialog and waits for the user's response.
///
/// - Returns: `true` if permission was granted, `false` if denied.
/// - Throws: On network errors or cancellation.
public func requestLocalNetworkAuthorization() async throws -> Bool {

    let queue = DispatchQueue(label: "\(Bundle.appBundleIdentifier ?? "app").localNetworkAuthCheck")

    let listener = try NWListener(using: NWParameters(tls: .none, tcp: NWProtocolTCP.Options()))
    listener.service = NWListener.Service(name: UUID().uuidString, type: serviceType)
    listener.newConnectionHandler = { _ in }

    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters)

    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in

            final class LocalState: @unchecked Sendable {
                var didResume = false
            }

            let local = LocalState()

            @Sendable func resume(with result: Result<Bool, any Error>) {
                if local.didResume { return }
                local.didResume = true

                listener.stateUpdateHandler = { _ in }
                browser.stateUpdateHandler = { _ in }
                browser.browseResultsChangedHandler = { _, _ in }
                listener.cancel()
                browser.cancel()

                continuation.resume(with: result)
            }

            if Task.isCancelled {
                resume(with: .failure(CancellationError()))
                return
            }

            listener.stateUpdateHandler = { newState in
                switch newState {
                case .setup, .ready, .waiting:
                    // .waiting is expected while the permission dialog is shown —
                    // do not resolve here. Only the browser drives the result.
                    break
                case .cancelled:
                    resume(with: .failure(CancellationError()))
                case let .failed(error):
                    log.error("Listener failed: \(error)")
                    resume(with: .failure(error))
                @unknown default:
                    break
                }
            }
            listener.start(queue: queue)

            browser.stateUpdateHandler = { newState in
                switch newState {
                case .setup, .ready:
                    break
                case .cancelled:
                    resume(with: .failure(CancellationError()))
                case let .failed(error):
                    log.error("Browser failed: \(error)")
                    resume(with: .failure(error))
                case let .waiting(error):
                    switch error {
                    case .dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied)):
                        log.info("Local network permission denied.")
                        resume(with: .success(false))
                    default:
                        log.error("Browser waiting: \(error)")
                        resume(with: .failure(error))
                    }
                @unknown default:
                    break
                }
            }

            browser.browseResultsChangedHandler = { results, _ in
                guard !results.isEmpty else { return }
                log.info("Local network permission granted.")
                resume(with: .success(true))
            }
            browser.start(queue: queue)

            if Task.isCancelled {
                resume(with: .failure(CancellationError()))
                return
            }
        }
    } onCancel: {
        listener.cancel()
        browser.cancel()
    }
}

#endif
