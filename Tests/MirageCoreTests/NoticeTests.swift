//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageCore
import Testing

// MARK: - Factory Methods

@Suite("Notice - Factory Methods")
struct NoticeFactoryTests {

    @Test("info creates notice with info kind")
    func infoKind() {
        let notice = Notice.info(summary: "All good")
        #expect(notice.kind == .info)
        #expect(notice.summary == "All good")
    }

    @Test("warning creates notice with warning kind")
    func warningKind() {
        let notice = Notice.warning(summary: "Watch out")
        #expect(notice.kind == .warning)
        #expect(notice.summary == "Watch out")
    }

    @Test("error creates notice with error kind")
    func errorKind() {
        let notice = Notice.error(summary: "Failed")
        #expect(notice.kind == .error)
        #expect(notice.summary == "Failed")
    }

    @Test("Factory methods pass through details and title")
    func detailsAndTitle() {
        let notice = Notice.info(summary: "Sum", details: "Det", title: "Title")
        #expect(notice.details == "Det")
        #expect(notice.title == "Title")
    }

    @Test("Factory methods default details and title to nil")
    func defaultsNil() {
        let notice = Notice.info(summary: "Sum")
        #expect(notice.details == nil)
        #expect(notice.title == nil)
    }
}

// MARK: - Error Factory

@Suite("Notice - Error Factory")
struct NoticeErrorFactoryTests {

    struct SimpleError: Error {}

    @Test("error from plain Error uses localizedDescription")
    func plainError() {
        let error = SimpleError()
        let notice = Notice.error(error)
        #expect(notice.kind == .error)
        #expect(!notice.summary.isEmpty)
    }

    @Test("error from plain Error has nil details")
    func plainErrorNilDetails() {
        let error = SimpleError()
        let notice = Notice.error(error)
        #expect(notice.details == nil)
    }

    @Test("error from MirageError uses summary")
    func mirageError() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Notice.error(error)
        #expect(notice.summary == "Bad JSON")
    }

    @Test("error with explicit title overrides MirageError title")
    func explicitTitle() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Notice.error(error, title: "Custom")
        #expect(notice.title == "Custom")
    }

    @Test("error with explicit details overrides MirageError details")
    func explicitDetails() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Notice.error(error, details: "Custom details")
        #expect(notice.details == "Custom details")
    }
}

// MARK: - Kind

@Suite("Notice - Kind")
struct NoticeKindTests {

    @Test("Kind has correct titles")
    func kindTitles() {
        #expect(Notice.Kind.info.title == "Info")
        #expect(Notice.Kind.warning.title == "Warning")
        #expect(Notice.Kind.error.title == "Error")
    }

    @Test("Kind is Comparable - info < warning < error")
    func kindOrdering() {
        #expect(Notice.Kind.info < .warning)
        #expect(Notice.Kind.warning < .error)
        #expect(!(Notice.Kind.error < .info))
    }

    @Test("Kind raw values are ordered")
    func kindRawValues() {
        #expect(Notice.Kind.info.rawValue == 0)
        #expect(Notice.Kind.warning.rawValue == 1)
        #expect(Notice.Kind.error.rawValue == 2)
    }
}

// MARK: - Hashable / Equatable

@Suite("Notice - Hashable")
struct NoticeHashableTests {

    @Test("Identical notices are equal")
    func identical() {
        let a = Notice.info(summary: "A", details: "D", title: "T")
        let b = Notice.info(summary: "A", details: "D", title: "T")
        #expect(a == b)
    }

    @Test("Different summaries are not equal")
    func differentSummary() {
        let a = Notice.info(summary: "A")
        let b = Notice.info(summary: "B")
        #expect(a != b)
    }

    @Test("Different kinds are not equal")
    func differentKind() {
        let a = Notice.info(summary: "A")
        let b = Notice.error(summary: "A")
        #expect(a != b)
    }

    @Test("Different details are not equal")
    func differentDetails() {
        let a = Notice.info(summary: "A", details: "X")
        let b = Notice.info(summary: "A", details: "Y")
        #expect(a != b)
    }

    @Test("Notices can be stored in a Set")
    func setStorage() {
        let a = Notice.info(summary: "A")
        let b = Notice.warning(summary: "B")
        let c = Notice.info(summary: "A")
        let set: Set<Notice> = [a, b, c]
        #expect(set.count == 2)
    }
}

// MARK: - Codable

@Suite("Notice - Codable")
struct NoticeCodableTests {

    @Test("Notice round-trips through JSON")
    func roundTrip() throws {
        let original = Notice.warning(summary: "Watch out", details: "Details here", title: "Warning Title")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Notice.self, from: data)
        #expect(decoded == original)
    }

    @Test("Notice with nil optionals round-trips")
    func roundTripNils() throws {
        let original = Notice.info(summary: "Simple")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Notice.self, from: data)
        #expect(decoded == original)
        #expect(decoded.details == nil)
        #expect(decoded.title == nil)
    }
}
