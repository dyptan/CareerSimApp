import SwiftUI

struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 16) {
            Text("Game Over")
                .font(.largeTitle.bold())
                .padding(.top)

            Text("You wrapped up your career at age \(player.age).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Money earned: \(player.savings.formatted(.number)) $")
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

            // The header no longer carries a running score, so this is the only
            // place the formula is spelled out — hence the full arithmetic
            // rather than a bare number. Debt counts against it, which is why
            // the caption says net worth and not savings.
            Text("🏅 Score: \(max(0, player.netWorth).formatted(.number)) $ ÷ \(player.age) y.o. = \(player.leaderboardScore.formatted(.number))")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Text("Your score is your net worth — savings minus any loans still owed — divided by your age. Building wealth younger scores higher.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                player.reset()
                appUIState.reset()
            } label: {
                Text("Restart")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            // The sheet also opens from the header's finish-game control, so an
            // accidental visit needs a way back that isn't wiping the run —
            // especially on macOS, where a sheet can't be swiped away.
            Button {
                appUIState.showRetirementSheet = false
            } label: {
                Text("Keep playing")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
        .onAppear { GameCenterManager.shared.submit(score: player.leaderboardScore) }
    }
}

/// Celebration shown the first time the mode's goal is reached. Only the
/// Simplified mode has a fixed goal (top leadership); the realistic settings are
/// open-ended and never trigger this (see `Player.goalMet`). Offers to keep
/// playing or start over.
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
        .onAppear { GameCenterManager.shared.submit(score: player.leaderboardScore) }
    }
}
