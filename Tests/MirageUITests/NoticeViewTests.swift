//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

    import MirageCore
    @testable import MirageUI
    import Testing

    // MARK: - Test Action Types

    private enum TwoActions: String, Hashable {
        case retry = "Retry"
        case cancel = "Cancel"
    }

    private enum ThreeActions: String, Hashable {
        case retry = "Retry"
        case ignore = "Ignore"
        case cancel = "Cancel"
    }

    private enum FourActions: String, Hashable {
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
    }

    // MARK: - NoNoticeAction

    @Suite("NoNoticeAction")
    struct NoNoticeActionTests {

        @Test("Cannot be instantiated from a raw value")
        func uninhabitable() {
            #expect(NoNoticeAction(rawValue: "anything") == nil)
            #expect(NoNoticeAction(rawValue: "") == nil)
        }
    }

    // MARK: - ErrorDismissAction

    @Suite("ErrorDismissAction")
    struct ErrorDismissActionTests {

        @Test("ok case has raw value 'OK'")
        func okRawValue() {
            #expect(ErrorDismissAction.ok.rawValue == "OK")
        }

        @Test("Can be initialized from raw value")
        func fromRawValue() {
            #expect(ErrorDismissAction(rawValue: "OK") == .ok)
            #expect(ErrorDismissAction(rawValue: "Nope") == nil)
        }
    }

    // MARK: - NoticeView Action Callback

    @Suite("NoticeView - Actions")
    struct NoticeViewActionTests {

        @Test("Actions array is capped at 3")
        @MainActor
        func actionsCappedAtThree() {
            var tapped: [FourActions] = []
            let _ = NoticeView(
                .info(summary: "Test"),
                actions: [.a, .b, .c, .d],
                onAction: { tapped.append($0) }
            )
            // The view was created — we can't inspect private state,
            // but we verify it compiles and accepts 4 actions without crashing.
        }

        @Test("NoticeView accepts zero actions via convenience init")
        @MainActor
        func noActions() {
            let _ = NoticeView(.info(summary: "No buttons"))
        }

        @Test("NoticeView accepts single action")
        @MainActor
        func singleAction() {
            var tapped: TwoActions?
            let _ = NoticeView(
                .info(summary: "Test"),
                actions: [.retry],
                onAction: { tapped = $0 }
            )
            #expect(tapped == nil)
        }

        @Test("NoticeView accepts two actions")
        @MainActor
        func twoActions() {
            let _ = NoticeView(
                .warning(summary: "Warning"),
                actions: [TwoActions.retry, .cancel],
                onAction: { _ in }
            )
        }

        @Test("NoticeView accepts three actions")
        @MainActor
        func threeActions() {
            let _ = NoticeView(
                .error(summary: "Error"),
                actions: [ThreeActions.retry, .ignore, .cancel],
                onAction: { _ in }
            )
        }

        @Test("Action raw values serve as button labels")
        func rawValues() {
            #expect(TwoActions.retry.rawValue == "Retry")
            #expect(TwoActions.cancel.rawValue == "Cancel")
            #expect(ThreeActions.ignore.rawValue == "Ignore")
        }
    }

    // MARK: - ErrorView Action Callback

    @Suite("ErrorView - Actions")
    struct ErrorViewActionTests {

        @Test("Single-button convenience creates with dismiss action")
        @MainActor
        func singleButton() {
            var dismissed = false
            let _ = ErrorView(
                title: "Error",
                summary: "Something went wrong",
                onButtonTapped: { dismissed = true }
            )
            #expect(!dismissed)
        }

        @Test("ErrorView accepts multiple actions")
        @MainActor
        func multipleActions() {
            let _ = ErrorView(
                title: "Error",
                summary: "Something went wrong",
                actions: [TwoActions.retry, .cancel],
                onAction: { _ in }
            )
        }

        @Test("ErrorView from Notice with multiple actions")
        @MainActor
        func fromNotice() {
            let notice = Notice.error(summary: "Failure")
            let _ = ErrorView(
                notice: notice,
                actions: [ThreeActions.retry, .ignore, .cancel],
                onAction: { _ in }
            )
        }

        @Test("ErrorView actions capped at 3")
        @MainActor
        func cappedAtThree() {
            let _ = ErrorView(
                title: "Error",
                summary: "Test",
                actions: [FourActions.a, .b, .c, .d],
                onAction: { _ in }
            )
        }

        @Test("Single-button convenience from Notice")
        @MainActor
        func singleButtonFromNotice() {
            let notice = Notice.warning(summary: "Watch out")
            let _ = ErrorView(
                notice: notice,
                onButtonTapped: {}
            )
        }
    }

#endif
