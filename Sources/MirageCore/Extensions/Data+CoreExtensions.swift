//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Core Data Extensions
extension Data: SummaryProviding {

    /// Default summary of Data
    /// If data can be converted into a UTF8 string of less than 1024 characters,
    /// that summary is returned, otherwise it's the byte count of the blob.
    public var summary: String {
        if count > 0, count <= 1024, let string = String(data: self, encoding: .utf8) {
            string
        } else {
            count.formatted(.byteCount(style: .memory))
        }
    }
}
