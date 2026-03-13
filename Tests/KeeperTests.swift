//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - KeychainError

#if canImport(Security)

@Suite("KeychainError")
struct KeychainErrorTests {

    @Test("itemNotFound has correct refcode and summary")
    func itemNotFound() {
        let error = KeeperError.itemNotFound(key: "myKey")
        #expect(error.refcode == "AXF9")
        #expect(error.summary.contains("myKey"))
        #expect(error.status == errSecItemNotFound)
        #expect(error.title == "Keychain Error")
    }

    @Test("saveFailed includes OSStatus")
    func saveFailed() {
        let error = KeeperError.saveFailed(key: "token", status: -25299)
        #expect(error.refcode == "4FJC")
        #expect(error.summary.contains("token"))
        #expect(error.status == -25299)
    }

    @Test("loadFailed includes OSStatus")
    func loadFailed() {
        let error = KeeperError.loadFailed(key: "secret", status: -25300)
        #expect(error.refcode == "4T85")
        #expect(error.summary.contains("secret"))
        #expect(error.status == -25300)
    }

    @Test("deleteFailed includes OSStatus")
    func deleteFailed() {
        let error = KeeperError.deleteFailed(key: "old", status: -25244)
        #expect(error.refcode == "9UUD")
        #expect(error.summary.contains("old"))
        #expect(error.status == -25244)
    }

    @Test("encodingFailed wraps underlying error")
    func encodingFailed() {
        struct TestError: Error {}
        let error = KeeperError.encodingFailed(key: "data", underlyingError: TestError())
        #expect(error.refcode == "WWKF")
        #expect(error.underlyingError is TestError)
    }

    @Test("decodingFailed wraps underlying error")
    func decodingFailed() {
        struct TestError: Error {}
        let error = KeeperError.decodingFailed(key: "data", underlyingError: TestError())
        #expect(error.refcode == "WWKF")
        #expect(error.underlyingError is TestError)
    }

    @Test("conforms to Yikes")
    func YikesConformance() {
        let error: any Yikes = KeeperError.itemNotFound(key: "test")
        #expect(error.summary.contains("test"))
        #expect(error.title == "Keychain Error")
    }
}

#endif

// MARK: - SelfSignedCertificateDelegate

#if canImport(Security)

@Suite("SelfSignedCertificateDelegate")
struct SelfSignedCertificateDelegateTests {

    @Test("Conforms to URLSessionDelegate and URLSessionTaskDelegate")
    func conformance() {
        // Protocol conformance is verified at compile time by the typed bindings.
        let _: any URLSessionDelegate = SelfSignedCertificateDelegate()
        let _: any URLSessionTaskDelegate = SelfSignedCertificateDelegate()
    }
}

#endif
