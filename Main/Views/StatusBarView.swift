import SwiftUI

/// Expandable history feed of player-facing milestones (graduations,
/// promotions, hires, layoffs, earned credentials, shipped projects). The
/// collapsed bar surfaces the most recent event so the player always knows
/// what just changed; expanding it reveals the full chronological log.
///
/// The feed is driven by `Player.statusEvents`, which is appended to from
/// `Player.advanceYear` and the few mutating helpers (hiring, founding,
/// graduation) that don't pass through it. `RootView` only shows the bar once
/// there's at least one event.
struct StatusBarView: View {
    @ObservedObject var player: Player

    @State private var isExpanded = false

    /// The ⓘ beside the bar, in the same voice as the main screen's section
    /// hints (see `SkillsView`).
    static var hint: String {
        [
            L("The big moments of your life so far — like finishing school, getting a job, a pay rise or a trophy."),
            L("The newest one is shown here. Open it to see them all, newest first."),
        ].joined(separator: "\n\n")
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(player.statusEvents.reversed()) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Text(event.icon)
                            Text("Age \(event.age) — \(event.message)")
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 160)
        } label: {
            if let latest = player.statusEvents.last {
                HStack(spacing: 6) {
                    Text(latest.icon)
                    Text("Age \(latest.age) — \(latest.message)")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    InfoHint(title: L("Your story"), message: Self.hint)
                }
                .font(.caption.bold())
            }
        }
    }
}
