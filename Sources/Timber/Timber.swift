//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Platform-agnostic logger wrapping `os.Logger` on Apple platforms
/// and falling back to `print` on Linux.
///
/// Timber has two goals: (1) make logging ergonomic so that regular
/// strings (not just string literals) can be passed as log messages and
/// (2) provide a basic, print-based logger for platforms without `os`.
///
/// An optional `sink` can be set at startup to forward log messages
/// to external storage (e.g. crash log, analytics). The sink receives
/// every log message; use ``enableLogStore(_:minimumLevel:)`` for
/// level-filtered persistence.

#if canImport(os)

    import os
    import Synchronization

    public struct Timber: Sendable {

        // MARK: - Sink

        /// Optional callback invoked for every log message.
        /// Set at app startup to forward log entries externally.
        public nonisolated(unsafe) static var sink: (
            @Sendable (_ level: Level, _ message: String, _ file: String, _ line: UInt) -> Void
        )?

        // MARK: - Level

        public enum Level: String, Comparable, Sendable {
            case debug
            case info
            case notice
            case error
            case fault

            private var severity: Int {
                switch self {
                case .debug: 0
                case .info: 1
                case .notice: 2
                case .error: 3
                case .fault: 4
                }
            }

            public static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.severity < rhs.severity
            }
        }

        // MARK: - Properties

        private let logger: os.Logger

        // MARK: - Initializers

        public init(subsystem: String? = nil, category: String? = nil) {
            let subsystem = subsystem ?? "MirageKit"
            let category: String = category ?? "Core"
            self.logger = os.Logger(subsystem: subsystem, category: category)
        }

        public init(subsystem: String, category: String) {
            self.logger = os.Logger(subsystem: subsystem, category: category)
        }

        // MARK: - Logging

        public func debug(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            logger.debug("\(message) [\(file):\(line)]")
            Self.sink?(.debug, message, file, line)
        }

        public func info(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            logger.info("\(message) [\(file):\(line)]")
            Self.sink?(.info, message, file, line)
        }

        public func notice(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            logger.notice("\(message) [\(file):\(line)]")
            Self.sink?(.notice, message, file, line)
        }

        public func error(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            logger.error("\(message) [\(file):\(line)]")
            Self.sink?(.error, message, file, line)
        }

        public func fault(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            logger.fault("\(message) [\(file):\(line)]")
            Self.sink?(.fault, message, file, line)
        }

        // MARK: - Convenience

        public func error(
            _ message: String,
            while task: String?,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(message)"
            } else {
                message
            }
            logger.error("\(formatted) [\(file):\(line)]")
            Self.sink?(.error, formatted, file, line)
        }

        public func error(
            _ error: any Error,
            while task: String? = nil,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(error)"
            } else {
                "\(error)"
            }
            logger.error("\(formatted) [\(file):\(line)]")
            Self.sink?(.error, formatted, file, line)
        }

        public func fault(
            _ message: String,
            while task: String?,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(message)"
            } else {
                message
            }
            logger.fault("\(formatted) [\(file):\(line)]")
            Self.sink?(.fault, formatted, file, line)
        }

        public func fault(
            _ error: any Error,
            while task: String? = nil,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(error)"
            } else {
                "\(error)"
            }
            logger.fault("\(formatted) [\(file):\(line)]")
            Self.sink?(.fault, formatted, file, line)
        }
    }

#else

    public struct Timber: Sendable {

        // MARK: - Sink

        public nonisolated(unsafe) static var sink: (
            @Sendable (_ level: Level, _ message: String, _ file: String, _ line: UInt) -> Void
        )?

        // MARK: - Level

        public enum Level: String, Comparable, Sendable {
            case debug
            case info
            case notice
            case error
            case fault

            private var severity: Int {
                switch self {
                case .debug: 0
                case .info: 1
                case .notice: 2
                case .error: 3
                case .fault: 4
                }
            }

            public static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.severity < rhs.severity
            }
        }

        // MARK: - Properties

        private let subsystem: String
        private let category: String

        // MARK: - Initializers

        public init(subsystem: String? = nil, category: String? = nil) {
            self.subsystem = if let subsystem {
                subsystem
            } else if let subsystem = Bundle.appName {
                subsystem
            } else if let subsystem = Bundle.appBundleIdentifier {
                subsystem
            } else {
                "MirageKit"
            }
            self.category = category ?? "Core"
        }

        public init(subsystem: String, category: String) {
            self.subsystem = subsystem
            self.category = category
        }

        // MARK: - Internal helpers

        private func emit(_ level: String, _ message: String, file: String, line: UInt) {
            print("\(subsystem).\(category) | \(level) \(message) [\(file):\(line)]")
        }

        // MARK: - Logging

        public func debug(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            emit("DEBUG", message, file: file, line: line)
            Self.sink?(.debug, message, file, line)
        }

        public func info(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            emit("INFO", message, file: file, line: line)
            Self.sink?(.info, message, file, line)
        }

        public func notice(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            emit("NOTICE", message, file: file, line: line)
            Self.sink?(.notice, message, file, line)
        }

        public func error(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            emit("ERROR", message, file: file, line: line)
            Self.sink?(.error, message, file, line)
        }

        public func fault(
            _ message: String,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            emit("FAULT", message, file: file, line: line)
            Self.sink?(.fault, message, file, line)
        }

        // MARK: - Convenience

        public func error(
            _ message: String,
            while task: String?,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(message)"
            } else {
                message
            }
            emit("ERROR", formatted, file: file, line: line)
            Self.sink?(.error, formatted, file, line)
        }

        public func error(
            _ error: any Error,
            while task: String? = nil,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(error)"
            } else {
                "\(error)"
            }
            emit("ERROR", formatted, file: file, line: line)
            Self.sink?(.error, formatted, file, line)
        }

        public func fault(
            _ message: String,
            while task: String?,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(message)"
            } else {
                message
            }
            emit("FAULT", formatted, file: file, line: line)
            Self.sink?(.fault, formatted, file, line)
        }

        public func fault(
            _ error: any Error,
            while task: String? = nil,
            file: String = #fileID,
            line: UInt = #line,
        ) {
            let formatted = if let task {
                "\(task) failed with error: \(error)"
            } else {
                "\(error)"
            }
            emit("FAULT", formatted, file: file, line: line)
            Self.sink?(.fault, formatted, file, line)
        }
    }

#endif

// MARK: - Shared Instance

public extension Timber {

    static let shared = Timber(subsystem: Bundle.appName, category: "Mirage")
}

// MARK: - Log Persistence

#if canImport(os)

    // MARK: - LogEntry

    /// A single persisted log entry produced by Timber.
    public struct TimberLogEntry: Codable, Identifiable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let level: String
        public let message: String
        public let file: String
        public let line: UInt
    }

    // MARK: - LogStore

    /// Persists log entries to a rotating JSON-lines file.
    ///
    /// Entries older than ``maxAge`` are pruned on load, and the store caps at
    /// ``maxEntries``, discarding the oldest when the limit is exceeded.
    public actor TimberLogStore {

        // MARK: - Constants

        public static let maxEntries = 500
        public static let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

        private static let fileName = "timber_log.jsonl"

        // MARK: - Singleton

        /// Shared store that writes to the app's document directory.
        public static let shared = TimberLogStore()

        // MARK: - Properties

        private var buffer: [TimberLogEntry] = []
        private let fileURL: URL
        private let jayson: Jayson
        private let generation = Mutex<Int>(0)

        // MARK: - Initializers

        /// Creates a store that writes to the app's document directory.
        ///
        /// Safe to force-unwrap: on Apple platforms (the only target for this code path,
        /// gated by `#if canImport(os)`) the documents directory is always present.
        /// If the sandbox were broken enough for this to fail, the app could not run at all.
        public init() {
            // swiftlint:disable:next force_unwrapping
            let docs = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask,
            ).first!
            self.init(directory: docs)
        }

        /// Creates a store that writes to the given directory.
        /// Useful for testing with a temporary directory.
        public init(directory: URL) {

            let fileURL = directory.appendingPathComponent(Self.fileName)
            self.fileURL = fileURL

            // Compact single-line JSON for JSONL format (no pretty printing).
            let jayson = Jayson(
                configuration: .init(
                    outputFormatting: [.sortedKeys, .withoutEscapingSlashes],
                ),
            )

            self.jayson = jayson

            // Load existing entries from disk
            if
                FileManager.default.fileExists(atPath: fileURL.path),
                let data = try? Data(contentsOf: fileURL)
            {
                let cutoff = Date().addingTimeInterval(-Self.maxAge)
                var entries = [TimberLogEntry]()

                for lineData in data.split(separator: UInt8(ascii: "\n")) {
                    if let entry = try? jayson
                        .decode(TimberLogEntry.self, from: Data(lineData))
                    {
                        if entry.timestamp > cutoff {
                            entries.append(entry)
                        }
                    }
                }

                if entries.count > Self.maxEntries {
                    entries = Array(entries.suffix(Self.maxEntries))
                }

                self.buffer = entries

                // Rewrite if we pruned expired or excess entries
                if entries.count != data.split(separator: UInt8(ascii: "\n")).count {
                    Self.writeEntries(entries, to: fileURL, using: jayson)
                }
            }
        }

        // MARK: - Public API

        /// The current generation counter. Incremented by ``deleteAll()``.
        /// Used by the sink to discard entries created before a clear.
        nonisolated public var currentGeneration: Int {
            generation.withLock { $0 }
        }

        /// All persisted entries, most recent first.
        public var entries: [TimberLogEntry] {
            buffer.reversed()
        }

        /// Number of persisted entries.
        public var entryCount: Int {
            buffer.count
        }

        /// Add a new entry to be persisted.
        public func append(
            level: Timber.Level,
            message: String,
            file: String,
            line: UInt,
        ) {
            appendEntry(level: level, message: message, file: file, line: line)
        }

        /// Add a new entry only if the store's generation still matches.
        ///
        /// When ``deleteAll()`` is called, the generation is incremented.
        /// Any in-flight `Task` that captured an earlier generation will
        /// silently drop its entry instead of re-adding it after a clear.
        public func append(
            generation: Int,
            level: Timber.Level,
            message: String,
            file: String,
            line: UInt,
        ) {
            guard generation == self.generation.withLock({ $0 }) else { return }
            appendEntry(level: level, message: message, file: file, line: line)
        }

        /// Delete all persisted entries and remove the backing file.
        public func deleteAll() {
            generation.withLock { $0 += 1 }
            buffer.removeAll()
            try? FileManager.default.removeItem(at: fileURL)
        }

        // MARK: - Private Helpers

        private func appendEntry(
            level: Timber.Level,
            message: String,
            file: String,
            line: UInt,
        ) {
            let entry = TimberLogEntry(
                id: UUID(),
                timestamp: Date(),
                level: level.rawValue,
                message: message,
                file: "\(file)",
                line: line,
            )

            buffer.append(entry)

            // Enforce max entries
            if buffer.count > Self.maxEntries {
                buffer.removeFirst(buffer.count - Self.maxEntries)
                rewriteFile()
            } else {
                appendToFile(entry)
            }
        }

        // MARK: - File I/O

        private func appendToFile(_ entry: TimberLogEntry) {

            guard let lineData = try? jayson.encode(entry) else { return }

            var data = lineData
            data.append(UInt8(ascii: "\n"))

            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }

        private func rewriteFile() {
            Self.writeEntries(buffer, to: fileURL, using: jayson)
        }

        private static func writeEntries(
            _ entries: [TimberLogEntry],
            to fileURL: URL,
            using jayson: Jayson,
        ) {
            var fileData = Data()
            for entry in entries {
                if let lineData = try? jayson.encode(entry) {
                    fileData.append(lineData)
                    fileData.append(UInt8(ascii: "\n"))
                }
            }
            try? fileData.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Timber + LogStore Integration

    public extension Timber {

        /// Wires a ``TimberLogStore`` into Timber's sink so that log
        /// messages at or above `minimumLevel` are persisted to disk.
        ///
        /// Call once at app startup:
        /// ```swift
        /// Timber.enableLogStore()                      // defaults to .error
        /// Timber.enableLogStore(minimumLevel: .notice)  // capture more
        /// ```
        static func enableLogStore(
            _ store: TimberLogStore = .shared,
            minimumLevel: Level = .error,
        ) {
            Timber.sink = { level, message, file, line in
                guard level >= minimumLevel else { return }
                let gen = store.currentGeneration
                Task {
                    await store.append(
                        generation: gen,
                        level: level,
                        message: message,
                        file: file,
                        line: line,
                    )
                }
            }
        }
    }

#endif
