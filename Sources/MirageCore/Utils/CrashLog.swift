//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

// Global C-string pointer (allocated with strdup at startup).
nonisolated(unsafe) var crashLogPathC: UnsafeMutablePointer<Int8>?

// C-compatible signal handler (signal-safe).
@_cdecl("crashSignalHandler")
nonisolated func crashSignalHandler(_ signum: Int32) {
    guard let path = crashLogPathC else {
        _exit(signum)
    }

    let fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, mode_t(0o644))
    if fd != -1 {
        // Convert signal number to ASCII
        var buffer = [UInt8]()
        var num = signum
        var digits = [UInt8]()
        repeat {
            digits.append(UInt8((num % 10) + 48)) // '0'..'9'
            num /= 10
        } while num > 0

        buffer.append(contentsOf: digits.reversed())

        _ = write(fd, buffer, buffer.count)
        close(fd)
    }

    _exit(signum)
}

/// Low-level crash logging.

public actor CrashLog {

    /// Singleton instance.
    public static let shared = CrashLog()

    /// Last recorded crash signal.
    public let crashSignal: CrashSignal?

    /// Enable monitoring for crashes. This is equivalent to accessing the singleton instance.
    public static func enable() {
        _ = shared
    }

    private init() {
        signal(SIGABRT, crashSignalHandler) // fatalError() -> abort -> SIGABRT
        signal(SIGSEGV, crashSignalHandler)
        signal(SIGBUS, crashSignalHandler)
        signal(SIGILL, crashSignalHandler)

        // Compute a stable path in the app container (Documents directory).
        // This is safe at init time (no signal handler running yet).
        let docs = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first!

        let crashLogURL = docs.appendingPathComponent("crash_log")

        // Convert to C string for the signal handler to use.
        // We leak this small allocation for app lifetime (fine for minimal usage).
        crashLogPathC = strdup(crashLogURL.path)

        if
            FileManager.default.fileExists(atPath: crashLogURL.path),
            let data = try? Data(contentsOf: crashLogURL),
            let string = String(data: data, encoding: .ascii),
            let signum = Int32(string)
        {
            self.crashSignal =
                switch signum {
                case SIGABRT:
                    .sigabort
                case SIGSEGV:
                    .sigsegv
                case SIGBUS:
                    .sigbus
                case SIGILL:
                    .sigill
                default:
                    .unknown(signum)
                }
        } else {
            self.crashSignal = nil
        }

        try? FileManager.default.removeItem(at: crashLogURL)
    }
}

public enum CrashSignal: CustomStringConvertible, Sendable {

    case sigabort
    case sigsegv
    case sigbus
    case sigill
    case unknown(Int32)

    public var description: String {
        switch self {
        case .sigabort:
            "SIGABRT (abort) — likely caused by fatalError() or assertion failure"
        case .sigsegv:
            "SIGSEGV (segmentation fault) — invalid memory access"
        case .sigbus:
            "SIGBUS (bus error) — invalid memory alignment or hardware fault"
        case .sigill:
            "SIGILL (illegal instruction) — invalid CPU instruction"
        case let .unknown(signum):
            "Signal \(signum) — unknown description"
        }
    }
}
