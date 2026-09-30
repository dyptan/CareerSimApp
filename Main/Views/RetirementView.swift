import SwiftUI

struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    /// Simplified is the tutorial: no score, no leaderboard — this sheet is
    /// just a progress check there (`Difficulty.keepsScore`).
    private var keepsScore: Bool { player.difficulty.keepsScore }

    var body: some View {
        VStack(spacing: 16) {
            // Opened from the header's Score button any time, and on its own at
            // the end of a career — so it reads as a progress check until the
            // run is actually over.
            Text(player.hasRetired ? "Game Over" : (keepsScore ? "Your score" : "Your progress"))
                .font(.largeTitle.bold())
                .padding(.top)

            Text(player.hasRetired
                 ? "You reached \(GameConstants.retirementAge) — your career is over\(keepsScore ? " and this score is final." : ".")"
                 : "You're \(player.age). Here's how your life is going so far — keep playing\(keepsScore ? " to grow your score" : ""), or start over.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("\(player.isSimplified ? "Money earned" : "Savings"): \(player.savings.formatted(.number)) $")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if player.outstandingLoan > 0 {
                Text("🏦 Venture loan owed: \(player.outstandingLoan.formatted(.number)) $")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            if player.studentLoan > 0 {
                Text("🎓 Student loan owed: \(player.studentLoan.formatted(.number)) $")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            // The header no longer carries the running score — this sheet, behind
            // the header's Score button, is where it lives, so the formula is
            // spelled out in full. Debt counts against it, which is why the
            // caption says net worth and not savings.
            if keepsScore {
                HStack(spacing: 6) {
                    Text("🏅 Score: \(max(0, player.netWorth).formatted(.number)) $ ÷ \(player.age) y.o. = \(player.leaderboardScore.formatted(.number))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    InfoHint(
                        title: "🏅 Score",
                        message: "What you own minus what you owe, divided by your age. The younger you build your savings, the higher your score."
                    )
                }
            }

            // The sheet opens from the header's Score button to check on the
            // run, so its main button is the way back to the game — especially
            // on macOS, where a sheet can't be swiped away — and wiping the run
            // is the secondary choice. Once the horizon is reached there is no
            // run left to go back to, so Restart is the only button.
            if !player.hasRetired {
                Button {
                    appUIState.showRetirementSheet = false
                } label: {
                    Text("Keep playing")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }

            if player.hasRetired {
                Button(action: startOver) {
                    Text("Restart")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            } else {
                Button(action: startOver) {
                    Text("Start over")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
        // Only a finished career submits on sight; checking the score mid-run
        // doesn't (see `startOver`).
        .onAppear {
            if player.hasRetired { GameCenterManager.shared.submitScore(of: player) }
        }
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

/// Celebration shown the first time the mode's goal is reached. Only the
/// Simplified mode has a fixed goal (top leadership); Real Life is open-ended
/// and never triggers this (see `Player.goalMet`). Offers to keep playing or
/// start over. The tutorial keeps no score, so nothing is banked here.
struct GoalView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    private var achievementText: String {
        let role = player.currentOccupation?.displayTitle ?? "a top leadership role"
        return "You climbed all the way to the top — you're now \(role)! 👔"
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
