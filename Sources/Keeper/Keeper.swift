//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(Security)

import Foundation
import Security

/// A secure key-value store backed by the system keychain.
///
/// Values are encoded/decoded with ``Jayson`` and stored as
/// `kSecClassGenericPassword` items keyed by the provided string key.
public struct Keeper: Sendable {

    private let service: String
    private let accessGroup: String?

    /// Creates a keychain store.
    ///
    /// - Parameters:
    ///   - service: The keychain service name. Defaults to the app's bundle identifier.
    ///   - accessGroup: An optional keychain access group for sharing between apps.
    public init(
        service: String? = nil,
        accessGroup: String? = nil,
    ) {
        self.service = service ?? Bundle.appBundleIdentifier ?? #fileID
        self.accessGroup = accessGroup
    }

    // MARK: - Operations

    public func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {

        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeeperError.itemNotFound(key: key)
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeeperError.loadFailed(key: key, status: status)
        }

        do {
            return try Jayson.shared.decode(T.self, from: data)
        } catch {
            throw KeeperError.decodingFailed(key: key, underlyingError: error)
        }
    }

    public func save(_ value: some Codable, forKey key: String) throws {

        let data: Data
        do {
            data = try Jayson.shared.encode(value)
        } catch {
            throw KeeperError.encodingFailed(key: key, underlyingError: error)
        }

        // Try to update an existing item first.
        let query = baseQuery(for: key)
        let attributes: [String: Any] = [kSecValueData as String: data]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist yet — add it.
            var addQuery = query
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeeperError.saveFailed(key: key, status: status)
        }
    }

    public func delete(key: String) throws {

        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeeperError.deleteFailed(key: key, status: status)
        }
    }

    // MARK: - Private

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

#endif
