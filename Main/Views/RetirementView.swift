import SwiftUI

struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState
    @ObservedObject private var gameCenter = GameCenterManager.shared

    /// The country's top 10, read from Game Center each time the sheet opens.
    @State private var board: LeaderboardState = .loading
    @State private var reloads = 0

    /// Simplified is the tutorial: no score, no leaderboard. Its header button
    /// restarts the run at once, so this sheet only appears there when the
    /// career is over (`Difficulty.keepsScore`).
    private var keepsScore: Bool { player.difficulty.keepsScore }

    /// The sheet's headline. Opened from the header's Leaderboard button any
    /// time in Real Life, and on its own at the end of a career — so it reads as
    /// the leaderboard until the run is actually over.
    private var heading: String {
        player.hasRetired ? L("Game Over") : L("Leaderboard")
    }

    /// One whole sentence per state. Before the end only a scored run gets here.
    private var summary: String {
        switch (player.hasRetired, keepsScore) {
        case (true, true):
            return L("You reached \(GameConstants.retirementAge) — your career is over and this score is final.")
        case (true, false):
            return L("You reached \(GameConstants.retirementAge) — your career is over.")
        case (false, _):
            return L("You're \(player.age). Here's how your life is going so far — keep playing to grow your score, or start over.")
        }
    }

    private var savingsLine: String {
        player.isSimplified
            ? L("Money earned: \(player.money(player.savings))")
            : L("Savings: \(player.money(player.savings))")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Text(heading)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    Text(summary)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    Text(savingsLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if player.outstandingLoan > 0 {
                        Text("🏦 Venture loan owed: \(player.money(player.outstandingLoan))")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }

                    if player.studentLoan > 0 {
                        Text("🎓 Student loan owed: \(player.money(player.studentLoan))")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }

                    // The running score lives on this sheet, behind the header's
                    // Leaderboard button, so the formula is spelled out in full. Debt
                    // counts against it, which is why the caption says net worth and
                    // not savings.
                    if keepsScore {
                        HStack(spacing: 6) {
                            Text("🏅 Score: \(player.money(max(0, player.netWorth))) ÷ \(player.age) y.o. = \(Fmt.number(player.leaderboardScore))")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            InfoHint(
                                title: L("🏅 Score"),
                                message: L("What you own minus what you owe, divided by your age. The younger you build your savings, the higher your score.")
                            )
                        }

                        LeaderboardSection(country: player.country, state: board, careerOver: player.hasRetired) {
                            reloads += 1
                        }
                    } else {
                        buttons.padding(.top, 8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // With a board to scroll through, the buttons stay put below it.
            if keepsScore {
                buttons
                    .padding([.horizontal, .bottom])
                    .padding(.top, 8)
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: keepsScore ? 560 : 400, idealHeight: keepsScore ? 700 : 440)
        #endif
        .task(id: [gameCenter.isAuthenticated ? 1 : 0, reloads]) { await refreshBoard() }
    }

    /// The sheet opens from the header's Leaderboard button to check on the run, so
    /// its main button is the way back to the game — especially on macOS,
    /// where a sheet can't be swiped away — and wiping the run is the secondary choice.
    /// Once the horizon is reached there is no run left to go back to, so Restart is the
    /// only button. The player's own line goes with them when it is further down than
    /// the top 10, so it stays in sight.
    private var buttons: some View {
        VStack(spacing: 16) {
            if case .loaded(_, let you?) = board {
                LeaderboardLine(row: you)
                    .frame(maxWidth: 480)
            }

            if !player.hasRetired {
                Button {
                    appUIState.showRetirementSheet = false
                } label: {
                    Text("Keep playing")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if player.hasRetired {
                Button(action: startOver) {
                    Text("Restart")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: startOver) {
                    Text("Start over")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// Reads the board. A finished career banks its score first, so the list already
    /// counts it; the task runs again when Game Center sign-in completes, which also
    /// banks a final score that was waiting for it.
    private func refreshBoard() async {
        guard keepsScore else { return }
        if player.hasRetired { await GameCenterManager.shared.submitScore(of: player).value }
        board = .loading
        board = await GameCenterManager.shared.loadLeaderboard(for: player.country)
    }

    /// Wipes the run and returns to the start screen. Starting over mid-run
    /// ends it early, so its score is banked now; a finished career banked it
    /// when the sheet appeared.
    private func startOver() {
        if !player.hasRetired {
            GameCenterManager.shared.submitScore(of: player)
        }
        player.reset()
        appUIState.reset()
    }
}

/// The country's ten best scores with the player's own line marked — or the reason
/// there is nothing to list. The score is money ÷ age in the country's own money, so
/// the list is the country's alone, the board the run's score goes to.
private struct LeaderboardSection: View {
    let country: Country
    let state: LeaderboardState
    /// A finished career has already posted its score, so the "posted when…" note no longer applies.
    let careerOver: Bool
    let retry: () -> Void

    private var place: String { "\(country.flag) \(country.title)" }

    var body: some View {
        VStack(spacing: 8) {
            Text("Top 10 · \(place)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            content
        }
        .frame(maxWidth: 480)
        .padding(.top, 8)
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, minHeight: 120)
        case .signedOut:
            note("Sign in to Game Center to see the leaderboard.")
        case .unavailable:
            note("The leaderboard isn't available right now.")
            Button("Try again", action: retry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .loaded(let top, let you):
            if top.isEmpty { note("No scores here yet.") }
            ForEach(Array(top.enumerated()), id: \.offset) { _, row in LeaderboardLine(row: row) }
            if !careerOver, you == nil, !top.contains(where: \.isLocalPlayer) {
                note("Your score is posted when your career ends, or when you start over.")
            }
        }
    }

    private func note(_ text: LocalizedStringResource) -> some View {
        Text(L(text))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}

/// One line of a board: the rank (a medal for the top three), the name and the score. The
/// player's own line says "You" and is marked.
private struct LeaderboardLine: View {
    let row: LeaderboardRow

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: Self.medal(for: row.rank) ?? Fmt.number(row.rank))
                .accessibilityLabel(Text(verbatim: Fmt.number(row.rank)))
                .frame(minWidth: 36, alignment: .trailing)
            Group {
                if row.isLocalPlayer {
                    Text("You", comment: "The player's own line in the leaderboard list (the other lines show other players' names)")  // i18n:ignore translator comment
                } else {
                    Text(verbatim: row.name)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: Fmt.number(row.score))
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.monospacedDigit())
        .fontWeight(row.isLocalPlayer ? .bold : .regular)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(row.isLocalPlayer ? Color.accentColor.opacity(0.18) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private static func medal(for rank: Int) -> String? {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
}

/// Celebration shown the first time the mode's goal is reached. Only the
/// Simplified mode has a fixed goal (top leadership); Real Life is open-ended
/// and never triggers this (see `Player.goalMet`). Offers to keep playing or
/// start over. The tutorial keeps no score, so nothing is banked here.
struct GoalView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    private var achievementText: String {
        guard let role = player.currentOccupation?.displayTitle else {
            return L("You climbed all the way to the top — you're now in a top leadership role! 👔")
        }
        return L("You climbed all the way to the top — you're now \(role)! 👔")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Goal reached!")
                .font(.largeTitle.bold())
                .padding(.top)

            Text(player.difficulty.goalHeadline)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(achievementText)
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Text("Reached at age \(player.age).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                appUIState.showGoalSheet = false
            } label: {
                Text("Keep playing")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Button {
                player.reset()
                appUIState.reset()
            } label: {
                Text("Start over")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
    }
}
