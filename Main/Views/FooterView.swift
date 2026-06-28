import SwiftUI

/// Wraps its subviews onto new rows when the proposed width runs out — used by
/// `FooterView` so its button rows reflow on narrow windows / split views
/// instead of clipping. iOS 16 / macOS 13 minimum (the deployment target's
/// `if #available` guards in `FooterView` provide a fallback).
@available(iOS 16, macOS 13, *)
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // The first item on a row never wraps; only check from item 2+.
            let prospective = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
            if prospective > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + lineSpacing
                widestRow = max(widestRow, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = prospective
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        widestRow = max(widestRow, rowWidth)
        return CGSize(width: maxWidth.isFinite ? maxWidth : widestRow, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Wraps `content` in `FlowLayout` on modern OS versions, falling back to a
/// plain `HStack` on iOS < 16 / macOS < 13. Keeps `FooterView`'s body free of
/// availability scaffolding.
private struct FooterButtonRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            FlowLayout(spacing: 8, lineSpacing: 8) { content() }
        } else {
            HStack { content() }
        }
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
    /// corresponding view applies, so we only render buttons that would lead
    /// to a non-empty sheet. (Existing prerequisite gates — degree EQF for
    /// Certifications/Licenses, work history for Events — stay in their own
    /// inline checks below.)
    private var hasHobbies: Bool {
        hobbies.contains { $0.stages.contains(currentStage) }
    }
    private var hasSports: Bool {
        Sport.allCases.contains { $0.stages.contains(currentStage) }
    }
    private var hasClubs: Bool {
        clubs.contains { $0.stages.contains(currentStage) }
    }
    private var hasCompetitions: Bool {
        CompetitionCatalog.all.contains { $0.stages.contains(currentStage) }
    }
    private var hasProjects: Bool {
        SideHustleCatalog.all.contains { $0.stages.contains(currentStage) }
    }
    private var hasCertifications: Bool {
        Certification.allCases.contains { $0.stages.contains(currentStage) }
    }
    private var hasLicenses: Bool {
        License.allCases.contains { $0.stages.contains(currentStage) }
    }

    var body: some View {
        // Private Certifications, Competitions, Licenses, and Events are
        // realistic-mode features, so hide them in simplified mode. Hobbies
        // stay — they build the soft skills that gate school admission.
        // Single wrapping row: every available button sits on one line when
        // the window is wide, and reflows onto extra rows as width shrinks.
        // Certifications / Licenses / Events keep their realistic-mode and
        // prerequisite gates; the rest are gated only by their stage-eligible
        // catalogues.
        FooterButtonRow {
            if hasHobbies {
                Button("Hobbies") { appUIState.showHobbiesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            if hasSports {
                Button("Sports") { appUIState.showSportsSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            if hasClubs {
                Button("Clubs") { appUIState.showClubsSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            if !player.isSimplified, !player.experience.isEmpty {
                Button("Events") { appUIState.showEventsSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            // Certifications: realistic mode, EQF ≥ Primary, and a
            // stage-eligible cert in the catalogue.
            if !player.isSimplified, (player.degrees.last?.eqf ?? 0) >= 1, hasCertifications {
                Button("Certifications") { appUIState.showCertificationsSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            // Licenses: realistic mode and EQF ≥ High School.
            if !player.isSimplified, (player.degrees.last?.eqf ?? 0) >= 3, hasLicenses {
                Button("Licenses") { appUIState.showLicensesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            if !player.isSimplified, hasCompetitions {
                Button("Competitions") { appUIState.showCompetitionsSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            Button("Jobs") {
                appUIState.showCareersSheet.toggle()
            }.buttonStyle(.bordered).font(.headline)

            if hasProjects {
                Button("Projects") { appUIState.showSideHustlesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            Button("Education") {
                appUIState.showTertiarySheet.toggle()
            }.buttonStyle(.bordered).font(.headline)

            Button("Next") {
                player.advanceYear(appUIState: appUIState)
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
}
