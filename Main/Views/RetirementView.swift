import SwiftUI

struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 16) {
            Text("Retirement")
                .font(.title2.bold())
                .padding(.top)

            Text("You've retired at age \(player.age).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Money earned: \(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
    }
}

/// Celebration shown the first time the active mode's goal is reached.
/// Offers to keep playing or start over.
struct GoalView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    private var achievementText: String {
        switch player.gameMode {
        case .simplified:
            let role = player.currentOccupation?.id ?? "a top leadership role"
            return "You climbed all the way to the top — you're now \(role)! 👔"
        case .realistic:
            return "You banked your first million! 💰\nSavings: \(player.savings.formatted(.number)) $"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Goal reached!")
                .font(.largeTitle.bold())
                .padding(.top)

            Text(player.gameMode.goalHeadline)
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
