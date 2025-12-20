//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public final class CSVBuilder {

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

    public func saveToDownloadsFolder(
        filename: String,
        refcode: String
    ) throws(CSVError) {

        rows.insert(headerRow, at: 0)

        let data = Data(text.utf8)

        do {
            let url = try FileManager.default.url(
                for: .downloadsDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent(filename)

            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw .saveToDownloadsFolder(
                filename: filename,
                data: data,
                error: error,
                refcode: refcode)
        }
    }

    public func save(to url: URL, refcode: String) throws(CSVError) {

        rows.insert(headerRow, at: 0)

        let data = Data(text.utf8)

        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw .saveTo(url, data: data, error: error, refcode: refcode)
        }
    }
}
