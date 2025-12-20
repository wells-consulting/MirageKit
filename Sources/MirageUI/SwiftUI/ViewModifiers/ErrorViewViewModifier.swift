//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

//
// Copyright 2026 Wells Consulting. All rights reserved.
//
// Mirage Player
//
// This source code is proprietary and confidential.
// Unauthorized copying, modification, distribution, or use of this file,
// in any medium, is strictly prohibited.
//
// This software is provided solely for use as part of the Mirage Player
// application and may not be used, disclosed, or redistributed outside
// of its intended private deployment without explicit written permission
// from the copyright holder.
//
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import SwiftUI
import MirageCore

private struct ErrorViewModifier: ViewModifier {

    @Binding var viewState: ErrorViewState

    var title: String {
        switch viewState {
        case .none:
            "Error Title: YOU_SHOULD_NEVER_SEE_THIS"
        case let .summary(error):
            (error as? (any MirageError))?.alertTitle ?? "Error"
        case let .details(error):
            (error as? (any MirageError))?.alertTitle ?? "Error"
        }
    }

    var summary: String {
        switch viewState {
        case .none:
            "Error Summary: YOU_SHOULD_NEVER_SEE_THIS"
        case let .summary(error):
            (error as? (any SummaryProviding))?.summary ?? error.localizedDescription
        case let .details(error):
            (error as? (any SummaryProviding))?.summary ?? error.localizedDescription
        }
    }

    var isDetailsButtonVisible: Bool {
        if case let .summary(error) = viewState {
            (error as? MirageError)?.details != nil
        } else {
            false
        }
    }

    func body(content: Content) -> some View {
        content
            .alert(
                title,
                isPresented: Binding(
                    get: { if case .summary = viewState { true } else { false } },
                    set: { _ in })
            ) {
                HStack {
                    if
                        case let .summary(error) = viewState,
                        (error as? MirageError)?.details != nil
                    {
                        Button("Show Details") {
                            viewState = .details(error)
                        }
                    }
                    Button("OK") {
                        viewState = .none
                    }
                }
            } message: {
                Text(summary)
            }
            .sheet(isPresented: Binding(
                get: { if case .details = viewState { true } else { false } },
                set: { _ in }
            )) {
                if case let .details(error) = viewState  {
                    ErrorView(error: error, buttonText: "OK") {
                        self.viewState = .none
                    }
                    .padding()
                    .frame(minWidth: 400)
                } else {
                    EmptyView().task { self.viewState = .none }
                }
            }
    }
}

public enum ErrorViewState {
    case none
    case summary(any Error)
    case details(any Error)
}

public extension View {
    func errorView(_ state: Binding<ErrorViewState>) -> some View {
        modifier(ErrorViewModifier(viewState: state))
    }
}

private struct PreviewTestObject: Codable {
    let intValue: Int
    let doubleValue: Double
    let stringValue: String

    static func encodeError() -> MirageError {
        var mirageError: MirageError?

        let invalidJSON = "{\"intValue\": \"not an int\", \"doubleValue\": 3.14, \"stringValue\": \"a string\""

        do {
            _ = try JSONCoder.shared.decode(PreviewTestObject.self, from: Data(invalidJSON.utf8))
        } catch {
            mirageError = JSONError(
                process: .decode,
                referenceCode: "\(#fileID):\(#function):\(#line)",
                clarification: "JSON decode failed.",
                underlyingErrors: [error])
        }

        return mirageError!
    }
}

#Preview {
    ErrorView(error: PreviewTestObject.encodeError()) {}
}

#endif
