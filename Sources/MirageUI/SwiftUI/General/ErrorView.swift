//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

    import MirageCore
    import SwiftUI

    /// A detailed error view with an icon, title, summary, optional details,
    /// optional diagnostics, and one or more action buttons.
    ///
    /// Like `NoticeView`, `ErrorView` is generic over an `Action` type that
    /// conforms to `RawRepresentable<String> & Hashable`. Each action case
    /// becomes a button whose label is the raw value.
    ///
    /// Up to 3 actions are supported.
    public struct ErrorView<Action: RawRepresentable & Hashable>: View where Action.RawValue == String {

        private let title: String
        private let summary: String
        private let details: String?
        private let diagnostics: String?
        private let actions: [Action]
        private let onAction: (Action) -> Void

        public init(
            error: any Error,
            options: MirageErrorUtils.ErrorDescriptionOptions,
            actions: [Action],
            onAction: @escaping (Action) -> Void,
        ) {
            self.title = (error as? (any MirageError))?.title ?? "Error"
            self.summary = (error as? (any MirageError))?.summary ?? error.localizedDescription
            self.details = (error as? (any MirageError))?.details
            self.diagnostics = (error as? (any MirageError))?.diagnostics(options: options)
            self.actions = Array(actions.prefix(3))
            self.onAction = onAction
        }

        public init(
            notice: Notice,
            actions: [Action],
            onAction: @escaping (Action) -> Void,
        ) {
            self.title = notice.title ?? notice.kind.title
            self.summary = notice.summary
            self.details = notice.details
            self.diagnostics = nil
            self.actions = Array(actions.prefix(3))
            self.onAction = onAction
        }

        public init(
            title: String,
            summary: String,
            details: String? = nil,
            actions: [Action],
            onAction: @escaping (Action) -> Void,
        ) {
            self.title = title
            self.summary = summary
            self.details = details
            self.diagnostics = nil
            self.actions = Array(actions.prefix(3))
            self.onAction = onAction
        }

        public var body: some View {
            VStack(alignment: .leading) {
                titleView
                descriptionView
                diagnosticsView
                Spacer()
                if !actions.isEmpty {
                    buttonsView
                }
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
            HStack(spacing: 12) {
                ForEach(actions, id: \.self) { action in
                    Button(action.rawValue) {
                        onAction(action)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Single-button convenience

    /// A single-action type used when ErrorView needs just one button (e.g. "OK").
    public enum ErrorDismissAction: String, Hashable {
        case ok = "OK"
    }

    public extension ErrorView where Action == ErrorDismissAction {

        /// Creates an error view with a single "OK" button.
        init(
            error: any Error,
            options: MirageErrorUtils.ErrorDescriptionOptions,
            buttonText: String = "OK",
            onButtonTapped: @escaping () -> Void,
        ) {
            self.title = (error as? (any MirageError))?.title ?? "Error"
            self.summary = (error as? (any MirageError))?.summary ?? error.localizedDescription
            self.details = (error as? (any MirageError))?.details
            self.diagnostics = (error as? (any MirageError))?.diagnostics(options: options)
            self.actions = [.ok]
            self.onAction = { _ in onButtonTapped() }
        }

        /// Creates an error view with a single "OK" button from a Notice.
        init(
            notice: Notice,
            buttonText: String = "OK",
            onButtonTapped: @escaping () -> Void,
        ) {
            self.title = notice.title ?? notice.kind.title
            self.summary = notice.summary
            self.details = notice.details
            self.diagnostics = nil
            self.actions = [.ok]
            self.onAction = { _ in onButtonTapped() }
        }

        /// Creates an error view with a single "OK" button from raw strings.
        init(
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
            self.actions = [.ok]
            self.onAction = { _ in onButtonTapped() }
        }
    }

    // MARK: - Previews

    private struct Test: Codable {
        let a: Int
        let b: String
        let c: URL

        static func decodeFailedError() -> any MirageError {
            do {
                _ = try Jayson.shared.decode(Test.self, from: Data("".utf8))
                throw NSError(domain: "Test", code: 0, userInfo: nil)
            } catch {
                return JaysonError(
                    process: .decode,
                    underlyingError: error,
                )
            }
        }
    }

    private enum PreviewAction: String { case retry = "Retry"; case cancel = "Cancel" }

    #Preview("Single button") {
        ErrorView(
            error: Test.decodeFailedError(),
            options: .verbose,
        ) {}
    }

    #Preview("Multiple buttons") {
        ErrorView(
            error: Test.decodeFailedError(),
            options: .verbose,
            actions: [PreviewAction.retry, .cancel],
        ) { action in
            print("Tapped: \(action.rawValue)")
        }
    }

#endif
