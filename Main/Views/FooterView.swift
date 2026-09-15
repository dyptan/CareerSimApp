import SwiftUI

/// Wraps its subviews onto new rows when the proposed width runs out — used by
/// `FooterView` so its button rows reflow on narrow windows / split views
/// instead of clipping.
///
/// A wrapping row: items flow left to right and wrap onto further lines.
///
/// Measurement and placement share one row-breaking pass, and the reported size
/// is the width actually used rather than the whole proposal. They used to
/// disagree — `sizeThatFits` wrapped against `proposal.width` and returned that
/// full width, while `placeSubviews` wrapped against `bounds.maxX`. When a
/// parent handed back a narrower bounds (here the footer's `Skip` button takes
/// its share first), placement produced more rows than measurement had reported,
/// so every row after the first rendered *outside* the layout's frame and
/// silently took no taps.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    /// One row-breaking pass, shared by measurement and placement so the two can
    /// never disagree about how many rows there are.
    private func rows(of subviews: Subviews, maxWidth: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = []
        var row: [(index: Int, size: CGSize)] = []
        var rowWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let prospective = row.isEmpty ? size.width : rowWidth + spacing + size.width
            // The first item on a row never wraps, however narrow the space.
            if prospective > maxWidth, !row.isEmpty {
                rows.append(row)
                row = [(index, size)]
                rowWidth = size.width
            } else {
                row.append((index, size))
                rowWidth = prospective
            }
        }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private func height(of rows: [[(index: Int, size: CGSize)]]) -> CGFloat {
        guard !rows.isEmpty else { return 0 }
        var total: CGFloat = 0
        for row in rows {
            total += row.reduce(0) { max($0, $1.size.height) }
        }
        return total + lineSpacing * CGFloat(rows.count - 1)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(of: subviews, maxWidth: maxWidth)
        var widest: CGFloat = 0
        for row in rows {
            let content: CGFloat = row.reduce(0) { $0 + $1.size.width }
            let gaps: CGFloat = spacing * CGFloat(max(0, row.count - 1))
            widest = max(widest, content + gaps)
        }
        // Claim only the width actually used: over-claiming lets a parent hand
        // back narrower bounds than were measured, which is what broke wrapping.
        return CGSize(width: min(widest, maxWidth), height: height(of: rows))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(of: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight: CGFloat = row.reduce(0) { max($0, $1.size.height) }
            for item in row {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (rowHeight - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }
}

/// Wraps `content` in `FlowLayout`. Keeps `FooterView`'s body free of layout
/// scaffolding.
private struct FooterButtonRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) { content() }
        // Styled once here rather than on each button, so the row stays uniform
        // as buttons are added. **Skip** sits outside this row and keeps its own
        // prominent style.
        .gameFooterButtonStyle()
    }
}


struct FooterView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    /// The player's current life stage, used to gate sheet buttons on whether
    /// the underlying catalogue actually has anything to show. The matching
    /// views all filter by this same stage internally, so an empty button row
    /// means the dialog would open onto an empty list.
    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// Per-button visibility: each predicate mirrors the catalogue filter the
    /// corresponding view applies, so we only render buttons that would lead to
    /// a non-empty sheet.
    private var hasHobbies: Bool {
        hobbies.contains { $0.stages.contains(currentStage) }
    }
    private var hasSports: Bool {
        Sport.allCases.contains { $0.stages.contains(currentStage) }
    }
    private var hasSideHustles: Bool {
        SideHustleCatalog.all.contains { $0.stages.contains(currentStage) }
    }

    var body: some View {
        // Everything the year can be spent on, and nothing else: letting a year
        // pass without spending it is **Skip**, up in the header. Events are a
        // realistic-mode feature, so they hide in simplified mode; hobbies stay,
        // since they build the soft skills that shape school admission odds.
        // Competitions have no button at all — they fire automatically each year
        // from the sport trained in Sports.
        activityButtons
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Everything the player can *do* with the year, as a row that wraps onto
    /// extra lines when the window is too narrow to hold it. Each button is
    /// gated only on whether its sheet would have anything in it.
    @ViewBuilder
    private var activityButtons: some View {
        FooterButtonRow {
            if hasHobbies {
                Button("Hobbies") { appUIState.showHobbiesSheet = true }
            }

            if hasSports {
                Button("Sports") { appUIState.showSportsSheet = true }
            }

            if !player.isSimplified, !player.experience.isEmpty {
                Button("Events") { appUIState.showEventsSheet = true }
            }

            // Jobs open up once the player reaches legal working age; before
            // that they're in school and nothing in the list is applicable.
            if player.age >= GameConstants.minimumWorkingAge {
                Button("Jobs") { appUIState.showCareersSheet.toggle() }
            }

            if hasSideHustles {
                Button("Projects") { appUIState.showSideHustlesSheet = true }
            }

            // The founder path is a realistic-mode adult play, and only one
            // venture runs at a time — once founded it becomes the occupation,
            // so this hides until the player exits it.
            if !player.isSimplified,
               player.age >= GameConstants.minimumEntrepreneurAge,
               player.currentOccupation?.isEntrepreneurial != true {
                Button("Ventures") { appUIState.showEntrepreneurshipSheet = true }
            }

            // Boardroom: senior-leadership strategy plays, shown only once the
            // player holds an executive seat (CEO, director, partner, founder).
            if player.canMakeExecutiveDecisions {
                Button("Boardroom") { appUIState.showExecutiveSheet = true }
            }

            // Education stays hidden until the player has graduated: through
            // all of school (K-12 wraps at 18) and again while a degree is in
            // progress — you pick your next study only once the current one is
            // done.
            if player.currentEducation == nil,
               player.age >= GameConstants.minimumTertiaryAge {
                Button("Education") { appUIState.showTertiarySheet.toggle() }
            }
        }
    }
}
