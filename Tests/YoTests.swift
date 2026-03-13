//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Factory Methods

@Suite("Yo - Factory Methods")
struct YoFactoryTests {

    @Test("info creates notice with info kind")
    func infoKind() {
        let notice = Yo.info(summary: "All good")
        #expect(notice.kind == .info)
        #expect(notice.summary == "All good")
    }

    @Test("warning creates notice with warning kind")
    func warningKind() {
        let notice = Yo.warning(summary: "Watch out")
        #expect(notice.kind == .warning)
        #expect(notice.summary == "Watch out")
    }

    @Test("error creates notice with error kind")
    func errorKind() {
        let notice = Yo.error(summary: "Failed")
        #expect(notice.kind == .error)
        #expect(notice.summary == "Failed")
    }

    @Test("Factory methods pass through details and title")
    func detailsAndTitle() {
        let notice = Yo.info(summary: "Sum", details: "Det", title: "Title")
        #expect(notice.details == "Det")
        #expect(notice.title == "Title")
    }

    @Test("Factory methods default details and title to nil")
    func defaultsNil() {
        let notice = Yo.info(summary: "Sum")
        #expect(notice.details == nil)
        #expect(notice.title == nil)
    }
}

// MARK: - Error Factory

@Suite("Yo - Error Factory")
struct NoticeErrorFactoryTests {

    struct SimpleError: Error {}

    @Test("error from plain Error uses localizedDescription")
    func plainError() {
        let error = SimpleError()
        let notice = Yo.error(error)
        #expect(notice.kind == .error)
        #expect(!notice.summary.isEmpty)
    }

    @Test("error from plain Error has nil details")
    func plainErrorNilDetails() {
        let error = SimpleError()
        let notice = Yo.error(error)
        #expect(notice.details == nil)
    }

    @Test("error from Yikes uses summary")
    func Yikes() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Yo.error(error)
        #expect(notice.summary == "Bad JSON")
    }

    @Test("error with explicit title overrides Yikes title")
    func explicitTitle() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Yo.error(error, title: "Custom")
        #expect(notice.title == "Custom")
    }

    @Test("error with explicit details overrides Yikes details")
    func explicitDetails() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Yo.error(error, details: "Custom details")
        #expect(notice.details == "Custom details")
    }
}

// MARK: - Kind

@Suite("Yo - Kind")
struct NoticeKindTests {

    @Test("Kind has correct titles")
    func kindTitles() {
        #expect(Yo.Kind.info.title == "Info")
        #expect(Yo.Kind.warning.title == "Warning")
        #expect(Yo.Kind.error.title == "Error")
    }

    @Test("Kind is Comparable - info < warning < error")
    func kindOrdering() {
        #expect(Yo.Kind.info < .warning)
        #expect(Yo.Kind.warning < .error)
        #expect(!(Yo.Kind.error < .info))
    }

    @Test("Kind raw values are ordered")
    func kindRawValues() {
        #expect(Yo.Kind.info.rawValue == 0)
        #expect(Yo.Kind.warning.rawValue == 1)
        #expect(Yo.Kind.error.rawValue == 2)
    }
}

// MARK: - Hashable / Equatable

@Suite("Yo - Hashable")
struct NoticeHashableTests {

    @Test("Identical notices are equal")
    func identical() {
        let a = Yo.info(summary: "A", details: "D", title: "T")
        let b = Yo.info(summary: "A", details: "D", title: "T")
        #expect(a == b)
    }

    @Test("Different summaries are not equal")
    func differentSummary() {
        let a = Yo.info(summary: "A")
        let b = Yo.info(summary: "B")
        #expect(a != b)
    }

    @Test("Different kinds are not equal")
    func differentKind() {
        let a = Yo.info(summary: "A")
        let b = Yo.error(summary: "A")
        #expect(a != b)
    }

    @Test("Different details are not equal")
    func differentDetails() {
        let a = Yo.info(summary: "A", details: "X")
        let b = Yo.info(summary: "A", details: "Y")
        #expect(a != b)
    }

    @Test("Notices can be stored in a Set")
    func setStorage() {
        let a = Yo.info(summary: "A")
        let b = Yo.warning(summary: "B")
        let c = Yo.info(summary: "A")
        let set: Set<Yo> = [a, b, c]
        #expect(set.count == 2)
    }
}

// MARK: - Codable

@Suite("Yo - Codable")
struct NoticeCodableTests {

    @Test("Notice round-trips through JSON")
    func roundTrip() throws {
        let original = Yo.warning(summary: "Watch out", details: "Details here", title: "Warning Title")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Yo.self, from: data)
        #expect(decoded == original)
    }

    @Test("Notice with nil optionals round-trips")
    func roundTripNils() throws {
        let original = Yo.info(summary: "Simple")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Yo.self, from: data)
        #expect(decoded == original)
        #expect(decoded.details == nil)
        #expect(decoded.title == nil)
    }
}
