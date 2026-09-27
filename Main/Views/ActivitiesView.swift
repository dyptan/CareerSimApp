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

    /// The sheet's title ⓘ: how levels, contests and the Study tab work.
    static let hint = """
    Picking an activity uses up your year.

    🏅 Every year you practise, you get better (Beginner → Expert) and you're entered in its biggest contest. Winning earns trophies and fame — and top universities like trophies.

    📝 Study activities also raise your school grade for the year, which colleges look at when you apply.

    🏆 on a row means you practised it last year — tap it to see this year's contest and your chance to win.
    """

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
