//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Core Array extensions
extension Array: SummaryProviding where Element: SummaryProviding {

    /// Default summary of an array
    public var summary: String {
        "[" + map(\.summary).joined(separator: ", ") + "]"
    }
}

/// For secret/sensitive strings that may need to be stored
/// This prevents analyzing the code or even the binary to
/// discover sensitive (but not critically so) data.
///
/// THIS IS NOT A SECURE WAY TO STORE KEYS, ETC. IT SHOULD
/// ONLY BE USED AS A SIMPLE WAY TO OBFUSCATE, NOT PROTECT
/// DATA.
///
/// Reference https://www.splinter.com.au/2019/05/05/obfuscating-keys/
///
/// ```swift
/// // Clear text
/// let clear: [UInt8] = [UInt8]("My_Sensitive_Data".data(using: .utf8)!)
///
/// // Generate the random data
/// let random: [UInt8] = (0..<clear.count).map { _ in UInt8(arc4random_uniform(256)) }
///
/// // Xor them together
/// let obfuscated: [UInt8] = zip(clear, random).map(^)
///
/// print(obfuscated + random)```
public extension [UInt8] {
    func decodeSecret() -> String {
        let r = prefix(count / 2)
        let x = suffix(count / 2)
        let bytes = zip(r, x).map(^)
        return String(bytes: bytes, encoding: .utf8)!
    }
}
