//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

private enum SettingLogger {
    static let log = Log(subsystem: Bundle.appName, category: "Setting<T>")
}

// UserDefaults does not support some optional primitive types such as Int?. This
// "box" type is used to wrap these types and allow nil return values.

private struct Scalar<T: Codable>: Codable {
    let value: T?
}

@propertyWrapper
public struct Setting<T: Codable> {

    let key: String
    let value: T?
    let defaultValue: T?

    public init(wrappedValue: T, key: String) {
        self.key = key
        self.value = wrappedValue
        self.defaultValue = wrappedValue
    }

    public init(wrappedValue: T, key: String, defaultValue: T?) {
        self.key = key
        self.value = wrappedValue
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T? {
        get { getValue(T.self, forKey: key) }
        set { setValue(newValue, forKey: key) }
    }

    private func getValue(_ type: T.Type, forKey key: String) -> T? {
        switch type {
        case is Bool.Type:
            getScalarValue(type, forKey: key)
        case is Int.Type:
            getScalarValue(type, forKey: key)
        case is Float.Type:
            getScalarValue(type, forKey: key)
        case is Double.Type:
            getScalarValue(type, forKey: key)
        case is URL.Type:
            UserDefaults.standard.url(forKey: key) as? T
        case is String.Type:
            UserDefaults.standard.string(forKey: key) as? T
        case is [String].Type:
            UserDefaults.standard.stringArray(forKey: key) as? T
        case is Data.Type:
            UserDefaults.standard.data(forKey: key) as? T
        default:
            getDecodableValue(type, forKey: key)
        }
    }

    private func getScalarValue(_ type: T.Type, forKey key: String) -> T? {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONCoder.shared.decode(
                    Scalar<T>.self,
                    from: data,
                    refcode: "MC7D").value
            } catch {
                SettingLogger.log.error(error, while: "Get Setting Value of type \(T.self) for '\(key)'")
                return defaultValue
            }
        } else {
            return defaultValue
        }
    }

    private func getDecodableValue(_ type: T.Type, forKey key: String) -> T? {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONCoder.shared.decode(
                    type,
                    from: data,
                    refcode: "J2RQ")
            } catch {
                SettingLogger.log.error(error, while: "Get Setting Value of type \(T.self) for '\(key)'")
                return defaultValue
            }
        } else {
            return defaultValue
        }
    }

    private func setValue(_ value: T?, forKey key: String) {
        switch T.self {
        case is Bool.Type:
            setScalarValue(value, forKey: key)
        case is Int.Type:
            setScalarValue(value, forKey: key)
        case is Float.Type:
            setScalarValue(value, forKey: key)
        case is Double.Type:
            setScalarValue(value, forKey: key)
        case is URL.Type:
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        case is String.Type:
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        case is [String].Type:
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        case is Data.Type:
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        default:
            setDecodableValue(value, forKey: key)
        }
    }

    private func setScalarValue(_ value: T?, forKey key: String) {
        if let value {
            do {
                let data = try JSONCoder.shared.encode(
                    Scalar<T>(value: value),
                    refcode: "CM8V")
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                SettingLogger.log.error(error, while: "Set Setting Value of type \(T.self) for '\(key)'")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func setDecodableValue(_ value: T?, forKey key: String) {
        if let value {
            do {
                let data = try JSONCoder.shared.encode(value, refcode: "RHVQ")
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                SettingLogger.log.error(error, while: "Set Setting Value of type \(T.self) for '\(key)'")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

private struct TestSettings {
    struct Fruit: Codable, Hashable {
        let name: String
        let colors: [String]
    }

    @Setting(key: "") var fruitSettings = Fruit(name: "Apple", colors: ["red", "green"])
}
