//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if false

import Foundation
import Synchronization

// UserDefaults does not support some optional primitive types such as Int?. This
// "box" type is used to wrap these types and allow nil return values.

private struct Scalar<T: Codable & Sendable>: Codable {
    let value: T?
}

@propertyWrapper
public struct Setting<T: Codable & Sendable> {

    let key: String
    let value: T?
    let defaultValue: T?

    public init(wrappedValue: T? = nil, key: String) {
        self.key = key
        self.value = wrappedValue
        self.defaultValue = wrappedValue
    }

    public init(wrappedValue: T? = nil, key: String, defaultValue: T?) {
        self.key = key
        self.value = wrappedValue
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T? {
        get { loadValue(T.self, forKey: key) }
        set { saveValue(newValue, forKey: key) }
    }

    private func loadValue(_ type: T.Type, forKey key: String) -> T? {
        UserDefaultsUtils.load(type, forKey: key) ?? defaultValue
    }

    private func saveValue(_ value: T?, forKey key: String) {
        do {
            try UserDefaultsUtils.save(value, forKey: key)
        } catch {
            Log.shared.error(error, while: "Saving Setting of \(T.self)")
        }
    }
}

// MARK: - Utilities

private enum Globals: Sendable {
    static let store: Mutex<UserDefaults> =
        .init(UserDefaults(suiteName: "MirageCore.Setting") ?? UserDefaults.standard)
}

public enum SettingUtils {

    public static func load<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: String
    ) throws -> T? {
        switch type {
        case is Bool.Type:
            try loadScalarValue(type, forKey: key)
        case is Int.Type:
            try loadScalarValue(type, forKey: key)
        case is Float.Type:
            try loadScalarValue(type, forKey: key)
        case is Double.Type:
            try loadScalarValue(type, forKey: key)
        case is URL.Type:
            Globals.store.withLock { store in
                store.url(forKey: key) as? T
            }
        case is String.Type:
            Globals.store.withLock { store in
                store.string(forKey: key) as? T
            }
        case is [String].Type:
            Globals.store.withLock { store in
                store.stringArray(forKey: key) as? T
            }
        case is Data.Type:
            Globals.store.withLock { store in
                store.data(forKey: key) as? T
            }
        default:
            try loadDecodableValue(type, forKey: key)
        }
    }

    private static func loadScalarValue<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: String
    ) throws -> T? {
        try Globals.store.withLock { store in
            if let data = store.data(forKey: key) {
                return try JSONCoder.shared.decode(
                    Scalar<T>.self,
                    from: data
                ).value
            } else {
                return nil
            }
        }
    }

    private static func loadDecodableValue<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: String
    ) throws -> T? {
        try Globals.store.withLock { store in
            if let data = store.data(forKey: key) {
                return try JSONCoder.shared.decode(
                    type,
                    from: data
                )
            } else {
                return nil
            }
        }
    }

    public static func save<T: Codable & Sendable>(
        _ value: T?,
        forKey key: String
    ) throws {
        switch T.self {
        case is Bool.Type:
            try saveScalarValue(value, forKey: key)
        case is Int.Type:
            try saveScalarValue(value, forKey: key)
        case is Float.Type:
            try saveScalarValue(value, forKey: key)
        case is Double.Type:
            try saveScalarValue(value, forKey: key)
        case is URL.Type:
            Globals.store.withLock { store in
                if let value {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
        case is String.Type:
            Globals.store.withLock { store in
                if let value {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
        case is [String].Type:
            Globals.store.withLock { store in
                if let value {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
        case is Data.Type:
            Globals.store.withLock { store in
                if let value {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
        default:
            try saveDecodableValue(value, forKey: key)
        }
    }

    private static func saveScalarValue<T: Codable & Sendable>(
        _ value: T?,
        forKey key: String
    ) throws {
        try Globals.store.withLock { store in
            if let value {
                let data = try JSONCoder.shared.encode(
                    Scalar<T>(value: value),
                    refcode: "CM8V"
                )
                store.set(data, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }
    }

    private static func saveDecodableValue<T: Codable & Sendable>(
        _ value: T?,
        forKey key: String
    ) throws {
        try Globals.store.withLock { store in
            if let value {
                let data = try JSONCoder.shared.encode(
                    value,
                    refcode: "RHVQ"
                )
                store.set(data, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }
    }
}

private struct TestSettings {
    struct Fruit: Codable, Hashable {
        let name: String
        let colors: [String]
    }

    @Setting(key: "") var fruitSettings: Fruit?
}

#endif
