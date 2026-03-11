//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageCore
import Testing

// MARK: - Test Helpers

/// Minimal conformer that only provides the required `summary`.
private struct MinimalError: MirageError {
    let summary: String
}

/// Full conformer that provides all optional properties.
private struct FullError: MirageError {
    let summary: String
    let title: String?
    let details: String?
    let underlyingError: (any Error)?
    let userInfo: [String: any Sendable]?
    let refcode: String?
}

/// A plain (non-Mirage) error for testing the non-MirageError path.
private struct PlainError: Error, CustomStringConvertible {
    let description: String
}

// MARK: - Protocol Defaults

@Suite("MirageError - Protocol Defaults")
struct MirageErrorDefaultsTests {

    @Test("summary is the only required property")
    func summaryRequired() {
        let error = MinimalError(summary: "Something broke")
        #expect(error.summary == "Something broke")
    }

    @Test("title defaults to nil")
    func titleDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.title == nil)
    }

    @Test("details defaults to nil")
    func detailsDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.details == nil)
    }

    @Test("underlyingError defaults to nil")
    func underlyingErrorDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.underlyingError == nil)
    }

    @Test("userInfo defaults to nil")
    func userInfoDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.userInfo == nil)
    }

    @Test("refcode defaults to nil")
    func refcodeDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.refcode == nil)
    }
}

// MARK: - LocalizedError

@Suite("MirageError - LocalizedError")
struct MirageErrorLocalizedTests {

    @Test("errorDescription is summary when no details")
    func errorDescriptionSummaryOnly() {
        let error = MinimalError(summary: "Oops")
        #expect(error.errorDescription == "Oops")
    }

    @Test("errorDescription combines summary and details")
    func errorDescriptionWithDetails() {
        let error = FullError(
            summary: "Oops",
            title: nil,
            details: "More info",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        #expect(error.errorDescription == "Oops\nMore info")
    }

    @Test("localizedDescription uses errorDescription")
    func localizedDescription() {
        let error = MinimalError(summary: "Crash")
        #expect(error.localizedDescription == "Crash")
    }
}

// MARK: - Full Conformer

@Suite("MirageError - Full Conformer")
struct MirageErrorFullConformerTests {

    @Test("All properties are accessible")
    func allProperties() {
        let underlying = PlainError(description: "disk full")
        let error = FullError(
            summary: "Save failed",
            title: "File Error",
            details: "Could not write to disk",
            underlyingError: underlying,
            userInfo: ["path": "/tmp/file"],
            refcode: "AB12"
        )
        #expect(error.summary == "Save failed")
        #expect(error.title == "File Error")
        #expect(error.details == "Could not write to disk")
        #expect(error.underlyingError is PlainError)
        #expect(error.userInfo?["path"] as? String == "/tmp/file")
        #expect(error.refcode == "AB12")
    }
}

// MARK: - ErrorDescriptionOptions

@Suite("ErrorDescriptionOptions")
struct ErrorDescriptionOptionsTests {

    @Test("minimal is empty")
    func minimal() {
        let opts = MirageErrorUtils.ErrorDescriptionOptions.minimal
        #expect(!opts.contains(.details))
        #expect(!opts.contains(.underlyingError))
        #expect(!opts.contains(.nsError))
    }

    @Test("basic includes details only")
    func basic() {
        let opts = MirageErrorUtils.ErrorDescriptionOptions.basic
        #expect(opts.contains(.details))
        #expect(!opts.contains(.underlyingError))
        #expect(!opts.contains(.nsError))
    }

    @Test("verbose includes details, underlyingError, and nsError")
    func verbose() {
        let opts = MirageErrorUtils.ErrorDescriptionOptions.verbose
        #expect(opts.contains(.details))
        #expect(opts.contains(.underlyingError))
        #expect(opts.contains(.nsError))
    }
}

// MARK: - describe() — Root-level behavior

@Suite("MirageErrorUtils.describe - Root Level")
struct DescribeRootTests {

    @Test("Root MirageError includes summary")
    func rootSummary() {
        let error = MinimalError(summary: "Request failed")
        let result = MirageErrorUtils.describe(error, options: .minimal)
        #expect(result.contains("Request failed"))
    }

    @Test("Root MirageError includes details with .basic")
    func rootDetails() {
        let error = FullError(
            summary: "Fail",
            title: nil,
            details: "Timeout after 30s",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(error, options: .basic)
        #expect(result.contains("Fail"))
        #expect(result.contains("Timeout after 30s"))
    }

    @Test("Root MirageError excludes details with .minimal")
    func rootNoDetails() {
        let error = FullError(
            summary: "Fail",
            title: nil,
            details: "Secret details",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(error, options: .minimal)
        #expect(!result.contains("Secret details"))
    }

    @Test("Root plain Error includes its description")
    func rootPlainError() {
        let error = PlainError(description: "disk full")
        let result = MirageErrorUtils.describe(error, options: .minimal)
        #expect(result.contains("disk full"))
    }

    @Test("Root error with no underlying returns non-empty string")
    func rootNonEmpty() {
        let error = MinimalError(summary: "Something")
        let result = MirageErrorUtils.describe(error, options: .verbose)
        #expect(!result.isEmpty)
    }
}

// MARK: - describe() — Underlying errors

@Suite("MirageErrorUtils.describe - Underlying Errors")
struct DescribeUnderlyingTests {

    @Test("Underlying MirageError is described")
    func underlyingMirageError() {
        let inner = MinimalError(summary: "Inner problem")
        let outer = FullError(
            summary: "Outer problem",
            title: nil,
            details: nil,
            underlyingError: inner,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(outer, options: .verbose)
        #expect(result.contains("Outer problem"))
        #expect(result.contains("Inner problem"))
        #expect(result.contains("Underlying Error"))
    }

    @Test("Underlying plain Error is described")
    func underlyingPlainError() {
        let inner = PlainError(description: "low-level failure")
        let outer = FullError(
            summary: "High-level failure",
            title: nil,
            details: nil,
            underlyingError: inner,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(outer, options: .verbose)
        #expect(result.contains("High-level failure"))
        #expect(result.contains("low-level failure"))
    }

    @Test("Underlying errors are skipped without .underlyingError option")
    func underlyingSkipped() {
        let inner = MinimalError(summary: "Hidden")
        let outer = FullError(
            summary: "Visible",
            title: nil,
            details: nil,
            underlyingError: inner,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(outer, options: .minimal)
        #expect(result.contains("Visible"))
        #expect(!result.contains("Hidden"))
    }

    @Test("Nested chain is fully described")
    func nestedChain() {
        let innermost = MinimalError(summary: "Root cause")
        let middle = FullError(
            summary: "Middle layer",
            title: nil,
            details: nil,
            underlyingError: innermost,
            userInfo: nil,
            refcode: nil
        )
        let outer = FullError(
            summary: "Top layer",
            title: nil,
            details: nil,
            underlyingError: middle,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(outer, options: .verbose)
        #expect(result.contains("Top layer"))
        #expect(result.contains("Middle layer"))
        #expect(result.contains("Root cause"))
    }

    @Test("Underlying error label includes type name")
    func typeNameInLabel() {
        let inner = PlainError(description: "boom")
        let outer = FullError(
            summary: "Wrapper",
            title: nil,
            details: nil,
            underlyingError: inner,
            userInfo: nil,
            refcode: nil
        )
        let result = MirageErrorUtils.describe(outer, options: .verbose)
        #expect(result.contains("PlainError"))
    }
}

// MARK: - describe() — NSError

@Suite("MirageErrorUtils.describe - NSError")
struct DescribeNSErrorTests {

    @Test("NSError info included with .nsError option")
    func nsErrorIncluded() {
        let nsError = NSError(domain: "com.test", code: 42, userInfo: nil)
        let result = MirageErrorUtils.describe(nsError, options: .verbose)
        #expect(result.contains("Domain=com.test"))
        #expect(result.contains("Code=42"))
    }

    @Test("NSError structured line excluded without .nsError option")
    func nsErrorExcluded() {
        let nsError = NSError(domain: "com.test", code: 42, userInfo: nil)
        let result = MirageErrorUtils.describe(nsError, options: .minimal)
        // The structured "Error Domain=..." line should not be present,
        // though NSError's own description may naturally contain domain info.
        #expect(!result.contains("Error Domain=com.test, Code=42"))
    }

    @Test("MirageCore domain is skipped to avoid redundancy")
    func mirageCoreSkipped() {
        let error = MinimalError(summary: "Test")
        let result = MirageErrorUtils.describe(error, options: .verbose)
        #expect(!result.contains("Domain=MirageCore"))
    }
}

// MARK: - diagnostics() convenience

@Suite("MirageError - diagnostics()")
struct DiagnosticsTests {

    @Test("diagnostics returns describe output")
    func diagnosticsOutput() {
        let error = FullError(
            summary: "Failed",
            title: nil,
            details: "Detail text",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let diag = error.diagnostics(options: .basic)
        #expect(diag?.contains("Failed") == true)
        #expect(diag?.contains("Detail text") == true)
    }

    @Test("diagnostics with minimal returns summary only")
    func diagnosticsMinimal() {
        let error = FullError(
            summary: "Just this",
            title: nil,
            details: "Not this",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let diag = error.diagnostics(options: .minimal)
        #expect(diag?.contains("Just this") == true)
        #expect(diag?.contains("Not this") != true)
    }
}
