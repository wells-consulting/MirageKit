//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import SwiftUI

/// A flow layout that progressively hides lower-priority items to
/// keep content on a single line. Items are hidden by visibility
/// priority (lowest priority first). If hiding all collapsible items
/// still can't fit on one line, remaining items wrap to additional rows.
///
/// Use `.visibilityPriority(_:)` to mark items as collapsible and
/// `.flowFlexible()` to let items expand into remaining row space.
public struct AdaptiveFlowLayout: Layout {

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
        let result = computeLayout(proposal: proposal, subviews: subviews)
        let hasFlexible = result.rows.contains { row in
            row.items.contains { $0.flexibility > 0 }
        }
        let width: CGFloat = if hasFlexible, let proposedWidth = proposal.width {
            proposedWidth
        } else {
            result.size.width
        }
        return CGSize(width: width, height: result.size.height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout (),
    ) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        let maxWidth = bounds.width
        var y = bounds.minY

        for row in result.rows {
            let remainingWidth = maxWidth - row.fixedWidth
            let totalPriority = row.items.reduce(CGFloat(0)) { $0 + $1.flexibility }

            var x = bounds.minX
            for item in row.items {
                var proposedWidth = item.idealSize.width
                if item.flexibility > 0, totalPriority > 0, remainingWidth > 0 {
                    proposedWidth += remainingWidth * (item.flexibility / totalPriority)
                }
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

        // Hidden subviews must still be placed. Position them well
        // off-screen because some views (SF Symbols) render at a
        // minimum intrinsic size even when proposed zero.
        for index in result.hiddenIndices {
            subviews[index].place(
                at: CGPoint(x: -10000, y: bounds.minY),
                anchor: .topLeading,
                proposal: .zero,
            )
        }
    }

    // MARK: - Layout Computation

    private struct ItemInfo {
        let index: Int
        let subview: LayoutSubview
        let idealSize: CGSize
        let visibilityPriority: Int
        let flexibility: CGFloat
        let minimumUsefulWidth: CGFloat
    }

    private struct RowItem {
        let subview: LayoutSubview
        let idealSize: CGSize
        let flexibility: CGFloat
    }

    private struct Row {
        var items: [RowItem] = []
        var fixedWidth: CGFloat = 0
        var height: CGFloat = 0
    }

    private struct LayoutResult {
        let rows: [Row]
        let hiddenIndices: Set<Int>
        let size: CGSize
    }

    private func computeLayout(
        proposal: ProposedViewSize,
        subviews: Subviews,
    ) -> LayoutResult {
        let maxWidth = proposal.width.flatMap { $0 > 0 ? $0 : nil } ?? .infinity

        // Gather info for all subviews.
        let allItems = subviews.enumerated().map { index, subview in
            ItemInfo(
                index: index,
                subview: subview,
                idealSize: subview.sizeThatFits(.unspecified),
                visibilityPriority: subview[VisibilityPriority.self],
                flexibility: subview[FlowFlexibility.self],
                minimumUsefulWidth: subview[MinimumUsefulWidth.self],
            )
        }

        // Unique visibility priorities > 0, sorted descending (highest number = lowest priority, hidden first).
        let priorities = Set(
            allItems.compactMap {
                $0.visibilityPriority > 0 ? $0.visibilityPriority : nil
            }
        )
            .sorted(by: >)

        var hiddenIndices = Set<Int>()
        var priorityIndex = 0

        func visibleItems() -> [ItemInfo] {
            allItems.filter { !hiddenIndices.contains($0.index) }
        }

        func singleRowWidth(_ items: [ItemInfo]) -> CGFloat {
            guard !items.isEmpty else { return 0 }
            let contentWidth = items.reduce(CGFloat(0)) { $0 + $1.idealSize.width }
            let spacingWidth = CGFloat(items.count - 1) * horizontalSpacing
            return contentWidth + spacingWidth
        }

        /// Returns the index of a flexible item whose expanded width
        /// would fall below its declared minimumUsefulWidth.
        func itemBelowMinimum(_ items: [ItemInfo]) -> Int? {
            let fixedWidth = singleRowWidth(items)
            let remainingWidth = maxWidth - fixedWidth
            let totalPriority = items.reduce(CGFloat(0)) { $0 + $1.flexibility }

            for item in items where item.minimumUsefulWidth > 0 {
                var expandedWidth = item.idealSize.width
                if item.flexibility > 0, totalPriority > 0, remainingWidth > 0 {
                    expandedWidth += remainingWidth * (item.flexibility / totalPriority)
                }
                if expandedWidth < item.minimumUsefulWidth {
                    return item.index
                }
            }
            return nil
        }

        // Try fitting visible items, progressively hiding by priority.
        // All priorities are exhausted before hiding items that can't
        // meet their minimumUsefulWidth, so lower-priority items
        // disappear first, freeing space for flexible items.
        while true {
            let visible = visibleItems()

            if singleRowWidth(visible) <= maxWidth {
                // Ideals fit — verify minimum useful widths are met.
                if itemBelowMinimum(visible) == nil {
                    return makeSingleRow(
                        from: visible,
                        hiddenIndices: hiddenIndices,
                        maxWidth: maxWidth
                    )
                }

                // A flex item can't meet its minimum. Try hiding
                // more items by priority to free up space.
                if priorityIndex < priorities.count {
                    let priority = priorities[priorityIndex]
                    for item in allItems where item.visibilityPriority == priority {
                        hiddenIndices.insert(item.index)
                    }
                    priorityIndex += 1
                    continue
                }

                // All ranks exhausted — hide the item that can't meet its minimum.
                if let belowMin = itemBelowMinimum(visibleItems()) {
                    hiddenIndices.insert(belowMin)
                    continue
                }
            }

            // Doesn't fit — hide next priority level if available.
            if priorityIndex < priorities.count {
                let priority = priorities[priorityIndex]
                for item in allItems where item.visibilityPriority == priority {
                    hiddenIndices.insert(item.index)
                }
                priorityIndex += 1
                continue
            }

            // No more ranks — wrap remaining items.
            return makeFlowRows(
                from: visibleItems(),
                hiddenIndices: hiddenIndices,
                maxWidth: maxWidth
            )
        }
    }

    private func makeSingleRow(
        from items: [ItemInfo],
        hiddenIndices: Set<Int>,
        maxWidth: CGFloat,
    ) -> LayoutResult {
        var row = Row()
        for item in items {
            let spacing = row.items.isEmpty ? 0 : horizontalSpacing
            row.items.append(
                RowItem(
                    subview: item.subview,
                    idealSize: item.idealSize,
                    flexibility: item.flexibility
                )
            )
            row.fixedWidth += spacing + item.idealSize.width
            row.height = max(row.height, item.idealSize.height)
        }
        return LayoutResult(
            rows: [row],
            hiddenIndices: hiddenIndices,
            size: CGSize(width: row.fixedWidth, height: row.height)
        )
    }

    private func makeFlowRows(
        from items: [ItemInfo],
        hiddenIndices: Set<Int>,
        maxWidth: CGFloat,
    ) -> LayoutResult {
        var rows: [Row] = [Row()]

        for item in items {
            let spacingNeeded = rows[rows.count - 1].items.isEmpty ? 0 : horizontalSpacing

            if rows[rows.count - 1].fixedWidth + spacingNeeded + item.idealSize.width > maxWidth,
               !rows[rows.count - 1].items.isEmpty
            {
                rows.append(Row())
            }

            let spacing = rows[rows.count - 1].items.isEmpty ? 0 : horizontalSpacing
            rows[rows.count - 1].items.append(
                RowItem(
                    subview: item.subview,
                    idealSize: item.idealSize,
                    flexibility: item.flexibility
                )
            )
            rows[rows.count - 1].fixedWidth += spacing + item.idealSize.width
            rows[rows.count - 1].height = max(
                rows[rows.count - 1].height,
                item.idealSize.height
            )
        }

        let totalHeight = rows.reduce(CGFloat(0)) { $0 + $1.height }
            + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let maxRowWidth = rows.reduce(CGFloat(0)) { max($0, $1.fixedWidth) }

        return LayoutResult(
            rows: rows,
            hiddenIndices: hiddenIndices,
            size: CGSize(width: maxRowWidth, height: totalHeight)
        )
    }
}

// MARK: - Layout Value Keys

private struct VisibilityPriority: LayoutValueKey {
    static let defaultValue: Int = 0
}

private struct MinimumUsefulWidth: LayoutValueKey {
    static let defaultValue: CGFloat = 0
}

public extension View {

    /// Sets the visibility priority for this view within an
    /// ``AdaptiveFlowLayout``. Priority 1 is the highest — items with
    /// higher numbers are hidden first when space is limited. Items
    /// without a priority (or priority 0) are never hidden.
    func mkVisibilityPriority(_ priority: Int) -> some View {
        layoutValue(key: VisibilityPriority.self, value: priority)
    }

    /// Sets the minimum width this view needs to be useful within an
    /// ``AdaptiveFlowLayout``. If the layout can't give the item at
    /// least this much width (after flexible expansion), the item is
    /// hidden entirely. Unlike `visibilityPriority`, this is checked
    /// after expansion — the ideal size stays small for measurement.
    func mkMinimumUsefulWidth(_ width: CGFloat) -> some View {
        layoutValue(key: MinimumUsefulWidth.self, value: width)
    }
}

#endif // canImport(SwiftUI)
