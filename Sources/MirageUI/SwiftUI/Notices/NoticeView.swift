//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

    import MirageCore
    import SwiftUI

    /// A view that displays a `Notice` with an optional set of action buttons.
    ///
    /// `NoticeView` is generic over an `Action` type that conforms to
    /// `RawRepresentable<String>` and `Hashable`. Each action case becomes a
    /// button whose label is the raw value. When a button is tapped the view
    /// calls `onAction` with the corresponding case, letting the caller switch
    /// on it at the call site.
    ///
    /// Up to 3 actions are supported. Any beyond that are silently ignored.
    ///
    /// Usage:
    /// ```swift
    /// enum AlertAction: String { case retry = "Retry"; case cancel = "Cancel" }
    ///
    /// NoticeView(.error(summary: "Failed"), actions: [.retry, .cancel]) { action in
    ///     switch action {
    ///     case .retry: // …
    ///     case .cancel: // …
    ///     }
    /// }
    /// ```
    ///
    /// For notices that need no buttons, use the convenience initializer:
    /// ```swift
    /// NoticeView(.info(summary: "All good"))
    /// ```
    public struct NoticeView<Action: RawRepresentable & Hashable>: View where Action.RawValue == String {

        private let notice: Notice
        private let actions: [Action]
        private let onAction: (Action) -> Void

        /// Creates a notice view with one or more action buttons.
        ///
        /// - Parameters:
        ///   - notice: The notice to display.
        ///   - actions: The action cases to present as buttons (max 3).
        ///   - onAction: Called when the user taps one of the buttons.
        public init(
            _ notice: Notice,
            actions: [Action],
            onAction: @escaping (Action) -> Void,
        ) {
            self.notice = notice
            self.actions = Array(actions.prefix(3))
            self.onAction = onAction
        }

        public var body: some View {
            VStack(spacing: 0) {
                NoticeIcon(notice)
                    .padding(.vertical, 16)

                if let title = notice.title {
                    Text(title)
                        .font(.title2)
                }

                Text(notice.summary)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                if let details = notice.details {
                    Text(details)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .padding()
                }

                if !actions.isEmpty {
                    buttonsView
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
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

    // MARK: - Convenience (no buttons)

    /// A type that can never be instantiated, used as the default action type
    /// when no buttons are needed. This allows `NoticeView(.info(summary: "…"))`
    /// without specifying a generic parameter.
    public struct NoNoticeAction: RawRepresentable, Hashable {
        public let rawValue: String
        public init?(rawValue: String) { nil }
    }

    public extension NoticeView where Action == NoNoticeAction {

        /// Creates a notice view with no action buttons.
        init(_ notice: Notice) {
            self.notice = notice
            self.actions = []
            self.onAction = { _ in }
        }
    }

#endif
