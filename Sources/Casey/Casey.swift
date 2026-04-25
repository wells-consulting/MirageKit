//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// A lightweight CSV builder that accumulates rows and writes them to a file.
///
/// Create a `Casey` with a header row, append data rows via ``addRow(_:)``,
/// then write the result to disk with ``save(to:)`` or
/// ``saveToDownloadsFolder(filename:)``. The header row is prepended
/// automatically at write time and is not included in ``text``.
///
/// ```swift
/// let csv = Casey(headerRow: "name,age,email")
/// csv.addRow("Alice,30,alice@example.com")
/// csv.addRow("Bob,25,bob@example.com")
/// try csv.saveToDownloadsFolder(filename: "users.csv")
/// ```
public final class Casey {

    private let headerRow: String
    private var rows: [String] = []

    /// Creates a new CSV document with the given header row.
    /// - Parameter headerRow: The comma-separated column names written as the
    ///   first line when the document is saved.
    public init(headerRow: String) {
        self.headerRow = headerRow
    }

    /// Appends a row to the document. `nil` values are silently ignored.
    /// - Parameter row: A comma-separated string representing one data row.
    public func addRow(_ row: String?) {
        guard let row else { return }
        rows.append(row)
    }

    /// The accumulated data rows joined by newlines. Does not include the header row.
    public var text: String {
        rows.joined(separator: "\n")
    }

    #if canImport(Darwin)
        /// Saves the document (header + rows) to the user's Downloads folder.
        /// - Parameter filename: The filename including extension (e.g. `"export.csv"`).
        /// - Throws: ``CaseyError`` if the Downloads directory cannot be located or the write fails.
        public func saveToDownloadsFolder(
            filename: String,
        ) throws(CaseyError) {

            rows.insert(headerRow, at: 0)

            let data = Data(text.utf8)

            do {
                let url = try FileManager.default.url(
                    for: .downloadsDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true,
                ).appendingPathComponent(filename)

                try data.write(to: url, options: [.atomic, .completeFileProtection])
            } catch {
                throw .saveToDownloadsFolder(
                    filename: filename,
                    data: data,
                    error: error,
                )
            }
        }
    #endif

    /// Saves the document (header + rows) to an arbitrary URL.
    /// - Parameter url: The destination file URL.
    /// - Throws: ``CaseyError`` if the write fails.
    public func save(to url: URL) throws(CaseyError) {

        rows.insert(headerRow, at: 0)

        let data = Data(text.utf8)

        do {
            #if canImport(Darwin)
                try data.write(to: url, options: [.atomic, .completeFileProtection])
            #else
                try data.write(to: url, options: [.atomic])
            #endif
        } catch {
            throw .saveTo(url, data: data, error: error)
        }
    }
}
