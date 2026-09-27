import SwiftUI

/// The career advisor's sheet: the few moves `CareerAdvisor` rates best right
/// now, each with a button that jumps to the sheet where it's made. Reading it
/// spends nothing — the year only moves once the player acts on a tip.
struct AdvisorView: View {
    @ObservedObject var player: Player
    /// Closes the advisor and opens the sheet a tip points to.
    let onGo: (CareerAdvisor.Destination) -> Void

    static let hint = """
    The advisor looks at your skills, your school and work so far, and this year's jobs. Then it suggests the moves most likely to help your career.

    📊 The best tips come first. A tip ranks higher when it's likely to work, pays more, and leaves you more years to enjoy it.

    The chances it shows are the game's real chances. Reading tips is free — it doesn't use up your year.
    """

    var body: some View {
        let tips = CareerAdvisor.tips(for: player)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if tips.isEmpty {
                    Text("Right now, the best move is to keep going! Keep building your skills and check back next year. 👍")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                        card(tip, isTopPick: index == 0)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func card(_ tip: CareerAdvisor.Tip, isTopPick: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(tip.icon)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 6) {
                if isTopPick {
                    Text("BEST MOVE")
                        .font(.caption2.bold())
                        .foregroundStyle(.tint)
                }
                Text(tip.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tip.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let destination = tip.destination {
                    Button(destination.buttonLabel) { onGo(destination) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    }
}
