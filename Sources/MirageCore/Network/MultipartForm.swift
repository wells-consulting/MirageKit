//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

private protocol MultipartFormContent {
    var name: String { get }
    var summary: String { get }
    func encode(into data: NSMutableData)
}

public final class MultipartForm {

    static let boundary = "AEE829AB-96ED-4566-9801-BBD497C33F7E"

    private var contents = [any MultipartFormContent]()

    public var isEmpty: Bool { contents.isEmpty }

    public var summary: String {
        contents.compactMap(\.summary).joined(separator: "\n")
    }

    public var data: Data {
        let data = NSMutableData()

        for content in contents {
            data.append(Data("\r\n--\(Self.boundary)\r\n".utf8))
            content.encode(into: data)
        }

        data.append(Data("\r\n--\(Self.boundary)--\r\n".utf8))

        return data as Data
    }

    public func contains(_ name: String) -> Bool {
        !contents.filter { $0.name.hasPrefix(name) }.isEmpty
    }

    public func getStringContentWithName(_ name: String) -> String? {
        if let content = contents.first(where: { $0 is StringContent && $0.name == name }) {
            (content as? StringContent)?.value
        } else {
            nil
        }
    }

    public func addingField(name: String, value: Bool) -> Self {
        contents.append(StringContent(value: value ? "true" : "false", name: name))
        return self
    }

    public func addingField(name: String, value: String) -> Self {
        contents.append(StringContent(value: value, name: name))
        return self
    }

    public func addingField(name: String, value: Int) -> Self {
        contents.append(StringContent(value: String(value), name: name))
        return self
    }

    public func addingField(name: String, value: Int32) -> Self {
        contents.append(StringContent(value: String(value), name: name))
        return self
    }

    public func addingField(name: String, value: Int64) -> Self {
        contents.append(StringContent(value: String(value), name: name))
        return self
    }

    public func addingField(name: String, value: Double) -> Self {
        contents.append(StringContent(value: String(value), name: name))
        return self
    }

    public func addingField(name: String, value: Date) -> Self {
        contents.append(StringContent(value: value.formatted(.iso8601), name: name))
        return self
    }

    public func addindField(name: String, value: UUID) -> Self {
        contents.append(StringContent(value: value.uuidString, name: name))
        return self
    }

    public func addingField(name: String, value: Data, savingTo filename: String) -> Self {
        contents.append(FileContent(value: value, name: name, filename: filename))
        return self
    }

    public func addingField(name: String, value: Data) throws -> Self {
        try contents.append(JSONContent(value: value, name: name))
        return self
    }

    struct StringContent: MultipartFormContent {

        let name: String
        let value: String

        var summary: String {
            """
            { "\(name)": "\(value)" }
            """
        }

        init(value: String, name: String) {
            self.name = name
            self.value = value
        }

        func encode(into data: NSMutableData) {
            data.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            data.append(Data(value.utf8))
        }
    }

    struct JSONContent: MultipartFormContent {

        let name: String
        let data: Data

        var summary: String {
            let dataByteCount = data.count.formatted(.byteCount(style: .memory))
            return """
                { "name": "\(name)", "data":"\(dataByteCount)" }
            """
        }

        init(value: Data, name: String) throws {
            self.name = name
            self.data = value
        }

        func encode(into data: NSMutableData) {
            data.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n".utf8))
            data.append(Data("Content-Type: application/json\r\n\r\n".utf8))
            data.append(self.data)
        }
    }

    struct FileContent: MultipartFormContent {

        let name: String
        let filename: String
        let data: Data

        var summary: String {
            let dataByteCount = data.count.formatted(.byteCount(style: .memory))
            return """
                { "name": "\(name)", "filename": "\(filename)", "data":"\(dataByteCount)" }
            """
        }

        init(value: Data, name: String, filename: String) {
            self.name = name
            self.filename = filename
            self.data = value
        }

        func encode(into data: NSMutableData) {
            data.append(Data("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".utf8))
            data.append(Data("Content-Type: application/octet-stream\r\n\r\n".utf8))
            data.append(self.data)
        }
    }
}
