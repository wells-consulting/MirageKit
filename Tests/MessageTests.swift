//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Factory Methods

@Suite("Message - Factory Methods")
struct MessageFactoryTests {

    @Test("info creates notice with info kind")
    func infoKind() {
        let notice = Message.info(summary: "All good")
        #expect(notice.kind == .info)
        #expect(notice.summary == "All good")
    }

    @Test("warning creates notice with warning kind")
    func warningKind() {
        let notice = Message.warning(summary: "Watch out")
        #expect(notice.kind == .warning)
        #expect(notice.summary == "Watch out")
    }

    @Test("error creates notice with error kind")
    func errorKind() {
        let notice = Message.error(summary: "Failed")
        #expect(notice.kind == .error)
        #expect(notice.summary == "Failed")
    }

    @Test("Factory methods pass through details and title")
    func detailsAndTitle() {
        let notice = Message.info(summary: "Sum", details: "Det", title: "Title")
        #expect(notice.details == "Det")
        #expect(notice.title == "Title")
    }

    @Test("Factory methods default details and title to nil")
    func defaultsNil() {
        let notice = Message.info(summary: "Sum")
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
        let notice = Message.error(error)
        #expect(notice.kind == .error)
        #expect(!notice.summary.isEmpty)
    }

    @Test("error from plain Error has nil details")
    func plainErrorNilDetails() {
        let error = SimpleError()
        let notice = Message.error(error)
        #expect(notice.details == nil)
    }

    @Test("error from Yikes uses summary")
    func Yikes() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Message.error(error)
        #expect(notice.summary == "Bad JSON")
    }

    @Test("error with explicit title overrides Yikes title")
    func explicitTitle() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Message.error(error, title: "Custom")
        #expect(notice.title == "Custom")
    }

    @Test("error with explicit details overrides Yikes details")
    func explicitDetails() {
        let error = JaysonError(process: .decode, summary: "Bad JSON")
        let notice = Message.error(error, details: "Custom details")
        #expect(notice.details == "Custom details")
    }
}

// MARK: - Kind

@Suite("Yo - Kind")
struct NoticeKindTests {

    @Test("Kind has correct titles")
    func kindTitles() {
        #expect(Message.Kind.info.title == "Info")
        #expect(Message.Kind.warning.title == "Warning")
        #expect(Message.Kind.error.title == "Error")
    }

    @Test("Kind is Comparable - info < warning < error")
    func kindOrdering() {
        #expect(Message.Kind.info < .warning)
        #expect(Message.Kind.warning < .error)
        #expect(!(Message.Kind.error < .info))
    }

    @Test("Kind raw values are ordered")
    func kindRawValues() {
        #expect(Message.Kind.info.rawValue == 0)
        #expect(Message.Kind.warning.rawValue == 1)
        #expect(Message.Kind.error.rawValue == 2)
    }
}

// MARK: - Hashable / Equatable

@Suite("Yo - Hashable")
struct NoticeHashableTests {

    @Test("Identical notices are equal")
    func identical() {
        let a = Message.info(summary: "A", details: "D", title: "T")
        let b = Message.info(summary: "A", details: "D", title: "T")
        #expect(a == b)
    }

    @Test("Different summaries are not equal")
    func differentSummary() {
        let a = Message.info(summary: "A")
        let b = Message.info(summary: "B")
        #expect(a != b)
    }

    @Test("Different kinds are not equal")
    func differentKind() {
        let a = Message.info(summary: "A")
        let b = Message.error(summary: "A")
        #expect(a != b)
    }

    @Test("Different details are not equal")
    func differentDetails() {
        let a = Message.info(summary: "A", details: "X")
        let b = Message.info(summary: "A", details: "Y")
        #expect(a != b)
    }

    @Test("Notices can be stored in a Set")
    func setStorage() {
        let a = Message.info(summary: "A")
        let b = Message.warning(summary: "B")
        let c = Message.info(summary: "A")
        let set: Set<Message> = [a, b, c]
        #expect(set.count == 2)
    }
}

// MARK: - Codable

@Suite("Yo - Codable")
struct NoticeCodableTests {

    @Test("Notice round-trips through JSON")
    func roundTrip() throws {
        let original = Message.warning(summary: "Watch out", details: "Details here", title: "Warning Title")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Message.self, from: data)
        #expect(decoded == original)
    }

    @Test("Notice with nil optionals round-trips")
    func roundTripNils() throws {
        let original = Message.info(summary: "Simple")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Message.self, from: data)
        #expect(decoded == original)
        #expect(decoded.details == nil)
        #expect(decoded.title == nil)
    }
}
