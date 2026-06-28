import SwiftUI

/// Expandable history feed of player-facing milestones (graduations,
/// promotions, hires, layoffs, earned credentials, shipped projects). The
/// collapsed bar surfaces the most recent event so the player always knows
/// what just changed; expanding it reveals the full chronological log.
///
/// The feed is driven by `Player.statusEvents`, which is appended to from
/// `Player.advanceYear` and the few mutating helpers (hiring, founding,
/// graduation) that don't pass through it.
struct StatusBarView: View {
    @ObservedObject var player: Player

    @State private var isExpanded = false

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
                }
                .font(.caption.bold())
            } else {
                Text("No milestones yet — keep playing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
