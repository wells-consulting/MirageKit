//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct ErrorView: View {

    private let title: String
    private let summary: String
    private let clarification: String?
    private let details: String?
    private let recoverySuggestion: String?
    private let diagnostics: String?
    private let buttonText: String
    private let onButtonTapped: () -> Void

    public init(
        error: any Error,
        buttonText: String = "Retry",
        onButtonTapped: @escaping () -> Void
    ) {
        self.title = (error as? (any MirageError))?.alertTitle ?? "Error"
        self.summary = (error as? (any MirageError))?.summary ?? (error as? (any LocalizedError)?)??.localizedDescription ?? "Unknown error."
        self.clarification = (error as? (any MirageError))?.clarification
        self.details = (error as? (any MirageError))?.details
        self.recoverySuggestion = (error as? (any MirageError))?.recovery
        self.diagnostics = (error as? (any MirageError))?.diagnostics
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(
        message: Message,
        buttonText: String = "Retry",
        onButtonTapped: @escaping () -> Void
    ) {
        self.title = message.title ?? message.severity.title ?? "Error"
        self.summary = message.summary
        self.clarification = nil
        self.details = message.details
        self.recoverySuggestion = nil
        self.diagnostics = nil
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(
        title: String,
        summary: String,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestions: String? = nil,
        buttonText: String = "Retry",
        onButtonTapped: @escaping () -> Void
    ) {
        self.title = title
        self.summary = summary
        self.clarification = clarification
        self.details = details
        self.recoverySuggestion = recoverySuggestions
        self.diagnostics = nil
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                #if os(tvOS)
                    .frame(width: 64, height: 64)
                #else
                    .frame(width: 32, height: 32)
                #endif
                    .foregroundStyle(.red)
                    .padding(.vertical, 16)

                Text(title)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(summary)
                    .multilineTextAlignment(.leading)
                if let clarification {
                    Text(clarification)
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let recoverySuggestion {
                    Label(recoverySuggestion, image: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let diagnostics {
                VStack(alignment: .leading) {
                    Text("Diagnostics")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                    ScrollView {
                        Text(diagnostics)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
//                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
//                .border(Color(.white), width: 1)
            }

            Button(action: { onButtonTapped() }, label: { Text(buttonText) })
                .buttonStyle(.bordered)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Previews

private struct Test: Codable {
    let a: Int
    let b: String
    let c: URL

    static func decodeFailedError() -> any MirageError {
        do {
            _ = try JSONCoder.shared.decode(Test.self, from: Data("".utf8), refcode: "ABC123")
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        } catch let error as any MirageError {
            return error
        } catch {
            return JSONError(
                process: .decode,
                refcode: "\(#fileID):\(#function):\(#line)",
                clarification: "JSON decode failed.",
                underlyingErrors: [error])
        }
    }
}

#Preview {
    ErrorView(error: Test.decodeFailedError()) {}
}

#endif
