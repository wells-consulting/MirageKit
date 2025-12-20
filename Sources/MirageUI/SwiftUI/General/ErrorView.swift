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
        private let details: String?
        private let diagnostics: String?
        private let buttonText: String
        private let onButtonTapped: () -> Void

        public init(
            error: any Error,
            options: MirageErrorUtils.ErrorDescriptionOptions,
            buttonText: String = "OK",
            onButtonTapped: @escaping () -> Void,
        ) {
            self.title = (error as? (any MirageError))?.alertTitle ?? "Error"
            self.summary = (error as? (any MirageError))?.summary ?? error.localizedDescription
            self.details = (error as? (any MirageError))?.details
            self.diagnostics = (error as? (any MirageError))?.diagnostics(options: options)
            self.buttonText = buttonText
            self.onButtonTapped = onButtonTapped
        }

        public init(
            message: Message,
            buttonText: String = "OK",
            onButtonTapped: @escaping () -> Void,
        ) {
            self.title = message.title ?? message.severity.title ?? "Error"
            self.summary = message.summary
            self.details = message.details
            self.diagnostics = nil
            self.buttonText = buttonText
            self.onButtonTapped = onButtonTapped
        }

        public init(
            title: String,
            summary: String,
            details: String? = nil,
            buttonText: String = "OK",
            onButtonTapped: @escaping () -> Void,
        ) {
            self.title = title
            self.summary = summary
            self.details = details
            self.diagnostics = nil
            self.buttonText = buttonText
            self.onButtonTapped = onButtonTapped
        }

        public var body: some View {
            VStack(alignment: .leading) {
                titleView
                descriptionView
                diagnosticsView
                Spacer()
                buttonsView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }

        @ViewBuilder
        private var titleView: some View {
            HStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                #if os(tvOS)
                    .frame(width: 40, height: 40)
                #else
                    .frame(width: 32, height: 32)
                #endif
                    .padding(.vertical, 16)

                Text(title)
                    .font(.title3)
            }
        }

        @ViewBuilder
        private var descriptionView: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary)
                    .multilineTextAlignment(.leading)
                if let details {
                    Text(details)
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        @ViewBuilder
        private var diagnosticsView: some View {
            if let diagnostics {
                VStack(alignment: .leading) {
                    Text("Diagnostics")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 2)
                    Text(diagnostics)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
            }
        }

        @ViewBuilder
        private var buttonsView: some View {
            HStack {
                Button(
                    action: { onButtonTapped() },
                    label: { Text(buttonText) },
                )
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Previews

    private struct Test: Codable {
        let a: Int
        let b: String
        let c: URL

        static func decodeFailedError() -> any MirageError {
            do {
                _ = try JSONCoder.shared.decode(Test.self, from: Data("".utf8))
                throw NSError(domain: "Test", code: 0, userInfo: nil)
            } catch {
                return JSONError(
                    process: .decode,
                    underlyingErrors: [error],
                )
            }
        }
    }

    #Preview {
        ErrorView(
            error: Test.decodeFailedError(),
            options: .verbose,
        ) {}
    }

#endif
