//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Platform agnostic OSLogger logging.
///
/// Linux implementations cannot, at this moment, import "os" that exposes
/// the new OS.Logger.
///
/// Log has two simple goals: (1) make logging a small bit more ergonomic
/// so that strings (not string literals) can be passed as log messages and
/// (2) provide a basic, print-based, logger for Linux.
///
/// Log should be a drop-in replacement for os.Logger.
///

public enum LogLevel {
    case debug      // OSLogType = debug, note trace is an alias
    case info       // OSLogType = info
    case notice     // OSLogType = notice (default)
    // case warning    // OSLogType = warning, an alias for error
    case error      // OSLogType = error
    // case critical   // OSLogType = critical, an alias for fault
    case fault      // OSLogType = fault
}

#if canImport(os)

import os

public struct Log: Sendable {

    private let logger: os.Logger

    public init(subsystem: String? = nil, category: String? = nil) {

        let subsystem: String = if let subsystem {
            subsystem
        } else if let subsystem = Bundle.appName {
            subsystem
        } else if let subsystem = Bundle.appBundleIdentifier {
            subsystem
        } else {
            "MirageKit"
        }

        let category: String = category ?? "Core"

        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func debug(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        logger.debug("\(message) [\(file):\(line)]")
    }

    public func info(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        logger.info("\(message) [\(file):\(line)]")
    }

    public func notice(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        logger.notice("\(message) [\(file):\(line)]")
    }

    public func error(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        logger.error("\(message) [\(file):\(line)]")
    }

    public func fault(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        logger.fault("\(message) [\(file):\(line)]")
    }
}

#else

public struct Log: Sendable {

    private let subsystem: String
    private let category: String

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

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func debug(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | DEBUG \(message) [\(file):\(line)]")
    }

    public func notice(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | NOTICE \(message) [\(file):\(line)]")
    }

    public func info(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | INFO \(message) [\(file):\(line)]")
    }

    public func error(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | ERROR \(message) [\(file):\(line)]")
    }

    public func fault(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | FAULT \(message) [\(file):\(line)]")
    }

    public func error(_ error: any Error, task: String? = nil, file: StaticString = #fileID, line: UInt = #line) {
        let message = if let task {
            "\(task) failed with error: \(error)"
        } else {
            "\(error)"
        }

        print("\(subsystem).\(category) | ERROR \(message) [\(file):\(line)]")
    }
}

#endif

public extension Log {

    static let shared = Log(subsystem: Bundle.appName, category: "Mirage")

    func error(
        _ message: String,
        while task: String? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let message = if let task {
            "\(task) failed with error: \(message)"
        } else {
            "\(message)"
        }

        logger.error("\(message) [\(file):\(line)]")
    }

    func error(
        _ error: any Error,
        while task: String? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let message = if let task {
            "\(task) failed with error: \(error)"
        } else {
            "\(error)"
        }

        logger.error("\(message) [\(file):\(line)]")
    }

    func fault(
        _ message: String,
        while task: String? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let message = if let task {
            "\(task) failed with error: \(message)"
        } else {
            "\(message)"
        }

        logger.fault("\(message) [\(file):\(line)]")
    }

    func fault(
        _ error: any Error,
        while task: String? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let message = if let task {
            "\(task) failed with error: \(error)"
        } else {
            "\(error)"
        }

        logger.fault("\(message) [\(file):\(line)]")
    }
}
