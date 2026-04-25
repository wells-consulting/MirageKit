//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

/// A layout that arranges its children horizontally, wrapping to the
/// next line when the available width is exceeded. Children marked
/// with `.flowFlexible()` expand to fill remaining row space.
public struct FlowLayout: Layout {

    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout (),
    ) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let hasFlexible = rows.rows.contains { row in
            row.items.contains { $0.priority > 0 }
        }
        // Flexible items expand to fill the proposed width, so report
        // that width instead of the natural (ideal) width.
        let width: CGFloat = if hasFlexible, let proposedWidth = proposal.width {
            proposedWidth
        } else {
            rows.size.width
        }
        return CGSize(width: width, height: rows.size.height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout (),
    ) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let maxWidth = bounds.width
        var y = bounds.minY

        for row in rows.rows {
            // Distribute remaining width to flexible items
            let remainingWidth = maxWidth - row.fixedWidth
            let totalPriority = row.items.reduce(CGFloat(0)) { $0 + $1.priority }

            var x = bounds.minX
            for item in row.items {
                var proposedWidth = item.idealSize.width
                if item.priority > 0, totalPriority > 0, remainingWidth > 0 {
                    proposedWidth += remainingWidth * (item.priority / totalPriority)
                }
                // Ask the subview what it actually accepts (respects maxWidth)
                let accepted = item.subview.sizeThatFits(
                    ProposedViewSize(width: proposedWidth, height: item.idealSize.height),
                )
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: proposedWidth, height: item.idealSize.height),
                )
                x += accepted.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    // MARK: - Row Computation

    private struct RowItem {
        let subview: LayoutSubview
        let idealSize: CGSize
        let priority: CGFloat
    }

    private struct Row {
        var items: [RowItem] = []
        var fixedWidth: CGFloat = 0
        var height: CGFloat = 0
    }

    private struct RowResult {
        let rows: [Row]
        let size: CGSize
    }

    private func computeRows(
        proposal: ProposedViewSize,
        subviews: Subviews,
    ) -> RowResult {
        let maxWidth = proposal.width.flatMap { $0 > 0 ? $0 : nil } ?? .infinity
        var rows: [Row] = [Row()]

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let priority = subview[FlowFlexibility.self]
            let spacingNeeded = rows[rows.count - 1].items.isEmpty ? 0 : horizontalSpacing

            if rows[rows.count - 1].fixedWidth + spacingNeeded + size.width > maxWidth,
               !rows[rows.count - 1].items.isEmpty
            {
                rows.append(Row())
            }

            let spacingActual = rows[rows.count - 1].items.isEmpty ? 0 : horizontalSpacing
            rows[rows.count - 1].items.append(RowItem(subview: subview, idealSize: size, priority: priority))
            rows[rows.count - 1].fixedWidth += spacingActual + size.width
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }

        let totalHeight = rows.reduce(CGFloat(0)) { $0 + $1.height }
            + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let maxRowWidth = rows.reduce(CGFloat(0)) { max($0, $1.fixedWidth) }

        return RowResult(rows: rows, size: CGSize(width: maxRowWidth, height: totalHeight))
    }
}

// MARK: - Flexibility Key

public struct FlowFlexibility: LayoutValueKey {
    public static let defaultValue: CGFloat = 0
}

public extension View {

    /// Marks this view as flexible within a ``FlowLayout``, allowing it
    /// to expand and fill remaining row space. Higher priority values
    /// receive a proportionally larger share of the extra width.
    func mkFlowFlexible(priority: CGFloat = 1) -> some View {
        layoutValue(key: FlowFlexibility.self, value: priority)
    }
}

#endif // canImport(SwiftUI)
