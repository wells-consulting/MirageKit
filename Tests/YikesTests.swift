//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Test Helpers

/// Minimal conformer that only provides the required `summary`.
private struct MinimalError: Yikes {
    let summary: String
}

/// Full conformer that provides all optional properties.
private struct FullError: Yikes {
    let summary: String
    let title: String?
    let details: String?
    let underlyingError: (any Error)?
    let userInfo: [String: any Sendable]?
    let refcode: String?
}

/// A plain (non-Mirage) error for testing the non-Yikes path.
private struct PlainError: Error, CustomStringConvertible {
    let description: String
}

// MARK: - Protocol Defaults

@Suite("Yikes - Protocol Defaults")
struct YikesDefaultsTests {

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

// MARK: - ErrorKind

@Suite("Yikes - ErrorKind")
struct YikesErrorKindTests {

    @Test("kind defaults to .persistent")
    func kindDefault() {
        let error = MinimalError(summary: "x")
        #expect(error.kind == .persistent)
    }

    @Test("EarlError kind is .configuration")
    func earlKind() {
        let error = EarlError.invalidURL(urlString: "not a url", urlComponents: nil)
        #expect(error.kind == .configuration)
    }

    @Test("LabradorError kind is .transient for 429")
    func labradorTransientStatusCode() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        let error = LabradorError(
            summary: "Too many requests.",
            httpURLResponse: response
        )
        #expect(error.kind == .transient)
    }

    @Test("LabradorError kind is .transient for 503")
    func labradorTransientServiceUnavailable() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        )
        let error = LabradorError(
            summary: "Service unavailable.",
            httpURLResponse: response
        )
        #expect(error.kind == .transient)
    }

    @Test("LabradorError kind is .persistent for 404")
    func labradorPersistentNotFound() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        let error = LabradorError(
            summary: "Not found.",
            httpURLResponse: response
        )
        #expect(error.kind == .persistent)
    }

    @Test("LabradorError kind is .transient for URLError.timedOut")
    func labradorTransientTimeout() {
        let error = LabradorError(
            summary: "Timed out.",
            underlyingError: URLError(.timedOut)
        )
        #expect(error.kind == .transient)
    }

    @Test("LabradorError kind is .persistent for URLError.cannotFindHost")
    func labradorPersistentBadHost() {
        let error = LabradorError(
            summary: "Bad host.",
            underlyingError: URLError(.cannotFindHost)
        )
        #expect(error.kind == .persistent)
    }

    @Test("JaysonError kind defaults to .persistent")
    func jaysonKind() {
        let error = JaysonError(process: .decode)
        #expect(error.kind == .persistent)
    }

    @Test("CaseyError kind defaults to .persistent")
    func caseyKind() {
        let error = CaseyError()
        #expect(error.kind == .persistent)
    }
}

// MARK: - LocalizedError

@Suite("Yikes - LocalizedError")
struct YikesLocalizedTests {

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

@Suite("Yikes - Full Conformer")
struct YikesFullConformerTests {

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
        let opts = DoesNotCompute.Options.minimal
        #expect(!opts.contains(.details))
        #expect(!opts.contains(.underlyingError))
        #expect(!opts.contains(.nsError))
    }

    @Test("basic includes details only")
    func basic() {
        let opts = DoesNotCompute.Options.basic
        #expect(opts.contains(.details))
        #expect(!opts.contains(.underlyingError))
        #expect(!opts.contains(.nsError))
    }

    @Test("verbose includes details, underlyingError, and nsError")
    func verbose() {
        let opts = DoesNotCompute.Options.verbose
        #expect(opts.contains(.details))
        #expect(opts.contains(.underlyingError))
        #expect(opts.contains(.nsError))
    }
}

// MARK: - describe() — Root-level behavior

@Suite("YikesUtils.describe - Root Level")
struct DescribeRootTests {

    @Test("Root Yikes includes summary")
    func rootSummary() {
        let error = MinimalError(summary: "Request failed")
        let result = DoesNotCompute.describe(error, options: .minimal)
        #expect(result.contains("Request failed"))
    }

    @Test("Root Yikes includes details with .basic")
    func rootDetails() {
        let error = FullError(
            summary: "Fail",
            title: nil,
            details: "Timeout after 30s",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let result = DoesNotCompute.describe(error, options: .basic)
        #expect(result.contains("Fail"))
        #expect(result.contains("Timeout after 30s"))
    }

    @Test("Root Yikes excludes details with .minimal")
    func rootNoDetails() {
        let error = FullError(
            summary: "Fail",
            title: nil,
            details: "Secret details",
            underlyingError: nil,
            userInfo: nil,
            refcode: nil
        )
        let result = DoesNotCompute.describe(error, options: .minimal)
        #expect(!result.contains("Secret details"))
    }

    @Test("Root plain Error includes its description")
    func rootPlainError() {
        let error = PlainError(description: "disk full")
        let result = DoesNotCompute.describe(error, options: .minimal)
        #expect(result.contains("disk full"))
    }

    @Test("Root error with no underlying returns non-empty string")
    func rootNonEmpty() {
        let error = MinimalError(summary: "Something")
        let result = DoesNotCompute.describe(error, options: .verbose)
        #expect(!result.isEmpty)
    }
}

// MARK: - describe() — Underlying errors

@Suite("YikesUtils.describe - Underlying Errors")
struct DescribeUnderlyingTests {

    @Test("Underlying Yikes is described")
    func underlyingYikes() {
        let inner = MinimalError(summary: "Inner problem")
        let outer = FullError(
            summary: "Outer problem",
            title: nil,
            details: nil,
            underlyingError: inner,
            userInfo: nil,
            refcode: nil
        )
        let result = DoesNotCompute.describe(outer, options: .verbose)
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
        let result = DoesNotCompute.describe(outer, options: .verbose)
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
        let result = DoesNotCompute.describe(outer, options: .minimal)
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
        let result = DoesNotCompute.describe(outer, options: .verbose)
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
        let result = DoesNotCompute.describe(outer, options: .verbose)
        #expect(result.contains("PlainError"))
    }
}

// MARK: - describe() — NSError

@Suite("YikesUtils.describe - NSError")
struct DescribeNSErrorTests {

    @Test("NSError info included with .nsError option")
    func nsErrorIncluded() {
        let nsError = NSError(domain: "com.test", code: 42, userInfo: nil)
        let result = DoesNotCompute.describe(nsError, options: .verbose)
        #expect(result.contains("Domain=com.test"))
        #expect(result.contains("Code=42"))
    }

    @Test("NSError structured line excluded without .nsError option")
    func nsErrorExcluded() {
        let nsError = NSError(domain: "com.test", code: 42, userInfo: nil)
        let result = DoesNotCompute.describe(nsError, options: .minimal)
        // The structured "Error Domain=..." line should not be present,
        // though NSError's own description may naturally contain domain info.
        #expect(!result.contains("Error Domain=com.test, Code=42"))
    }

    @Test("MirageCore domain is skipped to avoid redundancy")
    func mirageCoreSkipped() {
        let error = MinimalError(summary: "Test")
        let result = DoesNotCompute.describe(error, options: .verbose)
        #expect(!result.contains("Domain=MirageCore"))
    }
}

// MARK: - diagnostics() convenience

@Suite("Yikes - diagnostics()")
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

// MARK: - Refcode

@Suite("Refcode.derive")
struct RefcodeTests {

    @Test("Plain filename produces Domain.method")
    func plainFile() {
        let result = Refcode.derive(fileID: "App/Labrador.swift", caller: "execute()")
        #expect(result == "Labrador.execute")
    }

    @Test("Extension file strips base-class prefix")
    func extensionFileStripsPrefix() {
        let result = Refcode.derive(fileID: "App/StashBackend+Scene.swift", caller: "fetchData()")
        #expect(result == "Scene.fetchData")
    }

    @Test("Multiple plus signs: only suffix after last + is kept")
    func multiplePlus() {
        let result = Refcode.derive(fileID: "App/A+B+Scene.swift", caller: "load()")
        #expect(result == "Scene.load")
    }

    @Test("No module prefix in fileID still works")
    func noSlash() {
        let result = Refcode.derive(fileID: "Labrador.swift", caller: "fetch()")
        #expect(result == "Labrador.fetch")
    }

    @Test("caller with no parens uses full string")
    func callerNoParens() {
        let result = Refcode.derive(fileID: "App/Foo.swift", caller: "doWork")
        #expect(result == "Foo.doWork")
    }

    @Test("Extension file with no module prefix strips prefix")
    func extensionFileNoModule() {
        let result = Refcode.derive(fileID: "AppViewModel+Settings.swift", caller: "save()")
        #expect(result == "Settings.save")
    }
}
