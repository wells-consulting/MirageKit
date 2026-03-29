//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - Test Helper

/// Thread-safe box for capturing sink output in tests.
private final class SinkCapture: Sendable {
    nonisolated(unsafe) var level: Timber.Level?
    nonisolated(unsafe) var message: String?
    nonisolated(unsafe) var file: String?
    nonisolated(unsafe) var line: UInt?
    nonisolated(unsafe) var called: Bool = false
}

// MARK: - Level

@Suite("Timber.Level")
struct TimberLevelTests {

    @Test("Level raw values match expected strings")
    func rawValues() {
        #expect(Timber.Level.debug.rawValue == "debug")
        #expect(Timber.Level.info.rawValue == "info")
        #expect(Timber.Level.notice.rawValue == "notice")
        #expect(Timber.Level.error.rawValue == "error")
        #expect(Timber.Level.fault.rawValue == "fault")
    }

    @Test("Level can be initialized from raw value")
    func fromRawValue() {
        #expect(Timber.Level(rawValue: "debug") == .debug)
        #expect(Timber.Level(rawValue: "error") == .error)
        #expect(Timber.Level(rawValue: "unknown") == nil)
    }

    @Test("All five levels exist")
    func allLevels() {
        let levels: [Timber.Level] = [.debug, .info, .notice, .error, .fault]
        #expect(levels.count == 5)
    }

    @Test("Levels are ordered by severity")
    func ordering() {
        #expect(Timber.Level.debug < .info)
        #expect(Timber.Level.info < .notice)
        #expect(Timber.Level.notice < .error)
        #expect(Timber.Level.error < .fault)
    }

    @Test("Same level is not less than itself")
    func equalityNotLessThan() {
        #expect(!(Timber.Level.error < .error))
        #expect(Timber.Level.error >= .error)
    }
}

// MARK: - Initialization

@Suite("Timber - Initialization")
struct TimberInitTests {

    @Test("Default init does not crash")
    func defaultInit() {
        let log = Timber()
        log.debug("init test")
    }

    @Test("Init with explicit subsystem and category")
    func explicitInit() {
        let log = Timber(subsystem: "com.test", category: "Tests")
        log.debug("explicit init test")
    }

    @Test("Init with nil subsystem falls back")
    func nilSubsystem() {
        let log = Timber(subsystem: nil, category: nil)
        log.debug("nil init test")
    }

    @Test("Shared instance is accessible")
    func sharedInstance() {
        let log = Timber.shared
        log.debug("shared test")
    }
}

// MARK: - All tests that mutate Timber.sink (serialized to avoid races)

@Suite("Timber - Sink", .serialized)
struct TimberSinkTests {

    // MARK: - Basic Sink

    @Test("Sink receives error messages")
    func sinkReceivesError() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.error("something broke")

        #expect(capture.level == .error)
        #expect(capture.message == "something broke")
    }

    @Test("Sink receives fault messages")
    func sinkReceivesFault() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.fault("critical failure")

        #expect(capture.level == .fault)
        #expect(capture.message == "critical failure")
    }

    @Test("Sink receives debug messages")
    func sinkReceivesDebug() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.debug("debug message")

        #expect(capture.level == .debug)
        #expect(capture.message == "debug message")
    }

    @Test("Sink receives info messages")
    func sinkReceivesInfo() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.info("info message")

        #expect(capture.level == .info)
        #expect(capture.message == "info message")
    }

    @Test("Sink receives notice messages")
    func sinkReceivesNotice() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.notice("notice message")

        #expect(capture.level == .notice)
        #expect(capture.message == "notice message")
    }

    @Test("Sink receives file and line info")
    func sinkReceivesFileAndLine() {
        let capture = SinkCapture()

        Timber.sink = { _, _, file, line in
            capture.file = file
            capture.line = line
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "sink")
        log.error("test"); let expectedLine: UInt = #line

        #expect(capture.line == expectedLine)
        #expect(capture.file != nil)
    }

    @Test("Nil sink is safe")
    func nilSink() {
        Timber.sink = nil

        let log = Timber(subsystem: "test", category: "sink")
        log.error("no crash")
        log.fault("no crash")
    }

    // MARK: - Convenience Methods

    @Test("error with task formats message correctly")
    func errorWithTask() {
        let capture = SinkCapture()

        Timber.sink = { _, message, _, _ in
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "conv")
        log.error("timeout", while: "fetching data")

        #expect(capture.message == "fetching data failed with error: timeout")
    }

    @Test("error with nil task passes message through")
    func errorWithoutTask() {
        let capture = SinkCapture()

        Timber.sink = { _, message, _, _ in
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "conv")
        log.error("plain error", while: nil)

        #expect(capture.message == "plain error")
    }

    @Test("error with Error type formats message")
    func errorWithErrorType() {
        let capture = SinkCapture()

        Timber.sink = { _, message, _, _ in
            capture.message = message
        }
        defer { Timber.sink = nil }

        struct TestError: Error, CustomStringConvertible {
            let description = "test failure"
        }

        let log = Timber(subsystem: "test", category: "conv")
        log.error(TestError(), while: "saving")

        #expect(capture.message == "saving failed with error: test failure")
    }

    @Test("error with Error type and no task")
    func errorWithErrorTypeNoTask() {
        let capture = SinkCapture()

        Timber.sink = { _, message, _, _ in
            capture.message = message
        }
        defer { Timber.sink = nil }

        struct TestError: Error, CustomStringConvertible {
            let description = "bare error"
        }

        let log = Timber(subsystem: "test", category: "conv")
        log.error(TestError())

        #expect(capture.message == "bare error")
    }

    @Test("fault with task formats message correctly")
    func faultWithTask() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        let log = Timber(subsystem: "test", category: "conv")
        log.fault("corruption", while: "writing DB")

        #expect(capture.level == .fault)
        #expect(capture.message == "writing DB failed with error: corruption")
    }

    @Test("fault with Error type formats message")
    func faultWithErrorType() {
        let capture = SinkCapture()

        Timber.sink = { level, message, _, _ in
            capture.level = level
            capture.message = message
        }
        defer { Timber.sink = nil }

        struct FatalError: Error, CustomStringConvertible {
            let description = "fatal"
        }

        let log = Timber(subsystem: "test", category: "conv")
        log.fault(FatalError(), while: "startup")

        #expect(capture.level == .fault)
        #expect(capture.message == "startup failed with error: fatal")
    }

    // MARK: - enableLogStore

    #if canImport(os)

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimberSinkTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanUp(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    /// Polls the store until entryCount reaches the expected value, or times out.
    private func waitForEntryCount(
        _ expected: Int,
        in store: TimberLogStore,
        timeout: Duration = .milliseconds(2000)
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if await store.entryCount >= expected { return }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("enableLogStore routes errors to the store")
    func enableLogStoreRoutesErrors() async throws {
        let dir = try makeTempDir()
        defer {
            Timber.sink = nil
            cleanUp(dir)
        }

        let store = TimberLogStore(directory: dir)
        Timber.enableLogStore(store)

        let log = Timber(subsystem: "test", category: "logstore")
        log.error("persisted error")

        try await waitForEntryCount(1, in: store)

        let count = await store.entryCount
        #expect(count == 1)

        let entries = await store.entries
        #expect(entries[0].message == "persisted error")
        #expect(entries[0].level == "error")
    }

    @Test("enableLogStore routes faults to the store")
    func enableLogStoreRoutesFaults() async throws {
        let dir = try makeTempDir()
        defer {
            Timber.sink = nil
            cleanUp(dir)
        }

        let store = TimberLogStore(directory: dir)
        Timber.enableLogStore(store)

        let log = Timber(subsystem: "test", category: "logstore")
        log.fault("persisted fault")

        try await waitForEntryCount(1, in: store)

        let count = await store.entryCount
        #expect(count == 1)

        let entries = await store.entries
        #expect(entries[0].message == "persisted fault")
        #expect(entries[0].level == "fault")
    }

    @Test("enableLogStore default minimumLevel skips debug")
    func enableLogStoreSkipsDebug() async throws {
        let dir = try makeTempDir()
        defer {
            Timber.sink = nil
            cleanUp(dir)
        }

        let store = TimberLogStore(directory: dir)
        Timber.enableLogStore(store)

        let log = Timber(subsystem: "test", category: "logstore")
        log.debug("not persisted")

        // Give the sink time to process (debug is below default minimumLevel of .error)
        try await Task.sleep(for: .milliseconds(100))

        let count = await store.entryCount
        #expect(count == 0)
    }

    @Test("enableLogStore with minimumLevel .notice persists notice messages")
    func enableLogStoreCustomMinimumLevel() async throws {
        let dir = try makeTempDir()
        defer {
            Timber.sink = nil
            cleanUp(dir)
        }

        let store = TimberLogStore(directory: dir)
        Timber.enableLogStore(store, minimumLevel: .notice)

        let log = Timber(subsystem: "test", category: "logstore")
        log.notice("persisted notice")

        try await waitForEntryCount(1, in: store)

        let count = await store.entryCount
        #expect(count == 1)

        let entries = await store.entries
        #expect(entries[0].message == "persisted notice")
        #expect(entries[0].level == "notice")
    }

    @Test("enableLogStore with minimumLevel .notice skips info and debug")
    func enableLogStoreCustomMinimumLevelSkipsLower() async throws {
        let dir = try makeTempDir()
        defer {
            Timber.sink = nil
            cleanUp(dir)
        }

        let store = TimberLogStore(directory: dir)
        Timber.enableLogStore(store, minimumLevel: .notice)

        let log = Timber(subsystem: "test", category: "logstore")
        log.debug("not persisted")
        log.info("not persisted")

        // Give the sink time to process (both are below .notice)
        try await Task.sleep(for: .milliseconds(100))

        let count = await store.entryCount
        #expect(count == 0)
    }

    #endif
}

// MARK: - LogEntry

#if canImport(os)

@Suite("TimberLogEntry")
struct TimberLogEntryTests {

    @Test("LogEntry is Codable round-trip")
    func codableRoundTrip() throws {
        let entry = TimberLogEntry(
            id: UUID(),
            timestamp: Date(),
            level: "error",
            message: "something broke",
            file: "Test.swift",
            line: 42
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimberLogEntry.self, from: data)

        #expect(decoded.id == entry.id)
        #expect(decoded.level == entry.level)
        #expect(decoded.message == entry.message)
        #expect(decoded.file == entry.file)
        #expect(decoded.line == entry.line)
    }

    @Test("LogEntry has stable id for Identifiable")
    func identifiable() {
        let id = UUID()
        let entry = TimberLogEntry(
            id: id,
            timestamp: Date(),
            level: "fault",
            message: "msg",
            file: "F.swift",
            line: 1
        )
        #expect(entry.id == id)
    }
}

// MARK: - LogStore

@Suite("TimberLogStore", .serialized)
struct TimberLogStoreTests {

    /// Creates a fresh temp directory for each test.
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimberLogStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanUp(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Append and retrieve entries")
    func appendAndRetrieve() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        await store.append(level: .error, message: "err1", file: #fileID, line: #line)
        await store.append(level: .fault, message: "flt1", file: #fileID, line: #line)

        let count = await store.entryCount
        #expect(count == 2)

        let entries = await store.entries
        // entries is most-recent-first
        #expect(entries[0].message == "flt1")
        #expect(entries[0].level == "fault")
        #expect(entries[1].message == "err1")
        #expect(entries[1].level == "error")
    }

    @Test("Entries persist across re-init from same directory")
    func persistence() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store1 = TimberLogStore(directory: dir)
        await store1.append(level: .error, message: "persist me", file: #fileID, line: #line)

        // Create a new store from the same directory
        let store2 = TimberLogStore(directory: dir)
        let count = await store2.entryCount
        #expect(count == 1)

        let entries = await store2.entries
        #expect(entries[0].message == "persist me")
    }

    @Test("deleteAll removes all entries and file")
    func deleteAll() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        await store.append(level: .error, message: "gone", file: #fileID, line: #line)
        await store.deleteAll()

        let count = await store.entryCount
        #expect(count == 0)

        // File should not exist
        let fileURL = dir.appendingPathComponent("timber_log.jsonl")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("deleteAll increments generation")
    func deleteAllIncrementsGeneration() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        let gen0 = store.currentGeneration
        #expect(gen0 == 0)

        await store.deleteAll()
        let gen1 = store.currentGeneration
        #expect(gen1 == 1)

        await store.deleteAll()
        let gen2 = store.currentGeneration
        #expect(gen2 == 2)
    }

    @Test("append with matching generation succeeds")
    func appendWithMatchingGeneration() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        let gen = store.currentGeneration
        await store.append(generation: gen, level: .error, message: "kept", file: #fileID, line: #line)

        let count = await store.entryCount
        #expect(count == 1)
    }

    @Test("append with stale generation is silently dropped")
    func appendWithStaleGeneration() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        let staleGen = store.currentGeneration
        await store.deleteAll() // increments generation

        await store.append(generation: staleGen, level: .error, message: "stale", file: #fileID, line: #line)

        let count = await store.entryCount
        #expect(count == 0)
    }

    @Test("Entries are capped at maxEntries")
    func maxEntriesCap() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        // Pre-write maxEntries + 1 entries directly to the file
        // so we don't need 501 sequential actor calls.
        let fileURL = dir.appendingPathComponent("timber_log.jsonl")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let totalEntries = TimberLogStore.maxEntries + 1
        var data = Data()
        for i in 0 ..< totalEntries {
            let entry = TimberLogEntry(
                id: UUID(),
                timestamp: Date(),
                level: "error",
                message: "entry \(i)",
                file: "Test.swift",
                line: UInt(i)
            )
            data.append(try encoder.encode(entry))
            data.append(UInt8(ascii: "\n"))
        }
        try data.write(to: fileURL, options: .atomic)

        // Load the store — it should prune to maxEntries, keeping the newest
        let store = TimberLogStore(directory: dir)

        let count = await store.entryCount
        #expect(count == TimberLogStore.maxEntries)

        // Oldest entry (entry 0) should have been discarded
        let entries = await store.entries
        let messages = entries.map(\.message)
        #expect(!messages.contains("entry 0"))
        #expect(messages.contains("entry \(totalEntries - 1)"))
    }

    @Test("Expired entries are pruned on load")
    func prunesExpiredOnLoad() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        // Manually write an expired entry to the file
        let fileURL = dir.appendingPathComponent("timber_log.jsonl")
        let expired = TimberLogEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-(TimberLogStore.maxAge + 1)),
            level: "error",
            message: "old entry",
            file: "Old.swift",
            line: 1
        )
        let fresh = TimberLogEntry(
            id: UUID(),
            timestamp: Date(),
            level: "error",
            message: "new entry",
            file: "New.swift",
            line: 2
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var data = Data()
        data.append(try encoder.encode(expired))
        data.append(UInt8(ascii: "\n"))
        data.append(try encoder.encode(fresh))
        data.append(UInt8(ascii: "\n"))
        try data.write(to: fileURL, options: .atomic)

        // Load the store — expired entry should be pruned
        let store = TimberLogStore(directory: dir)
        let count = await store.entryCount
        #expect(count == 1)

        let entries = await store.entries
        #expect(entries[0].message == "new entry")
    }

    @Test("entryCount matches entries.count")
    func entryCountMatchesEntries() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        await store.append(level: .error, message: "a", file: #fileID, line: #line)
        await store.append(level: .fault, message: "b", file: #fileID, line: #line)
        await store.append(level: .error, message: "c", file: #fileID, line: #line)

        let count = await store.entryCount
        let entries = await store.entries
        #expect(count == entries.count)
        #expect(count == 3)
    }

    @Test("Entries record file and line")
    func recordsFileAndLine() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        let expectedLine: UInt = #line + 1
        await store.append(level: .error, message: "loc", file: #fileID, line: expectedLine)

        let entries = await store.entries
        #expect(entries[0].file.contains("TimberTests"))
        #expect(entries[0].line == expectedLine)
    }

    @Test("Empty store on fresh directory")
    func emptyOnFreshDir() async throws {
        let dir = try makeTempDir()
        defer { cleanUp(dir) }

        let store = TimberLogStore(directory: dir)
        let count = await store.entryCount
        #expect(count == 0)

        let entries = await store.entries
        #expect(entries.isEmpty)
    }
}

#endif
