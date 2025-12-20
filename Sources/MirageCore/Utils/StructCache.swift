//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// In-memory cache for immutable structs using NSCache.

public actor StructCache<StructType: Sendable> {

    private let cache = NSCache<NSString, Wrapper<StructType>>()

    public init() {}

    /// Get a value from the cache.
    ///
    /// - Parameters:
    ///     - key: Unique key for value
    public func getValue(key: String) -> StructType? {
        cache.object(forKey: key as NSString)?.value
    }

    /// Set a value into the cache.
    ///
    /// - Parameters:
    ///     - value: Value to cache
    ///     - key: Unique key for value
    public func setValue(_ value: StructType?, key: String) {
        if let value {
            cache.setObject(Wrapper(value), forKey: key as NSString)
        } else {
            cache.removeObject(forKey: key as NSString)
        }
    }

    private final class Wrapper<ValueType: Sendable> {
        let value: ValueType
        init(_ value: ValueType) {
            self.value = value
        }
    }
}
