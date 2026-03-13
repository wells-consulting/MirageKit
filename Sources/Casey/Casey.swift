//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public final class Casey {

    private let headerRow: String
    private var rows: [String] = []

    public init(headerRow: String) {
        self.headerRow = headerRow
    }

    public func addRow(_ row: String?) {
        guard let row else { return }
        rows.append(row)
    }

    public var text: String {
        rows.joined(separator: "\n")
    }

    #if canImport(Darwin)
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
