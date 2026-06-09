//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.

import Foundation

/// Types providing safe and/or redacted log text.
public protocol LogTextProviding {
    var logText: String { get }
}
