import SwiftUI

/// The **Activities** sheet: every discipline the year's spare-time slot can go
/// on — taking any one spends the year. Only disciplines that level up and
/// compete belong here (see `Sport`); a segmented switch splits them into
/// Sports, Arts & Minds and (while at school) Study, so each list stays short
/// on a small phone.
struct ActivitiesView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState
    /// Taking an activity spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// The tabs with something to take at the player's age. The footer shows
    /// the Activities button only when this isn't empty.
    static func availableTabs(for player: Player) -> [ActivityKind] {
        ActivityKind.allCases.filter { !ActivityListView.offered(to: player, kind: $0).isEmpty }
    }

    private var tabs: [ActivityKind] { Self.availableTabs(for: player) }

    /// The remembered tab (it lives in `AppUIState`, so it survives the sheet
    /// closing every year), falling back to the first one open at this age.
    private var shownTab: ActivityKind {
        tabs.contains(appUIState.activitiesTab) ? appUIState.activitiesTab : (tabs.first ?? .sports)
    }

    var body: some View {
        VStack(spacing: 8) {
            // A single open tab needs no switch.
            if tabs.count > 1 {
                Picker("Activity", selection: $appUIState.activitiesTab) {
                    ForEach(tabs) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
            }

            // The competition hook, stated once for the whole sheet rather than
            // only inside each row's hint.
            HStack(spacing: 6) {
                Text("🏅 Every year you practise, you level up and enter its top contest.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                InfoHint(
                    title: "🏅 Levels & contests",
                    message: "Each year spent on an activity moves you up a level — Beginner, Intermediate, Advanced, Expert — and automatically enters you in the best contest you qualify for. There's no entry step. More years and stronger skills raise your odds and unlock bigger contests. Wins earn trophies and fame in that field — and selective universities count trophies at admission.\n\nPractise an activity and, the next year, a 🏆 button on its row shows the contest you'd enter and your odds."
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal)

            // What makes the Study tab different from the other two.
            if shownTab == .study {
                Text("📝 A year of study also lifts your school grade — and universities, the elite ones most of all, read your grades.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            ActivityListView(
                player: player,
                kind: shownTab,
                selectedActivities: $appUIState.selectedActivities,
                selectedSports: $appUIState.selectedSports,
                onCommit: onCommit
            )
        }
    }
}

#Preview {
    ActivitiesView(player: Player(), appUIState: AppUIState())
}
