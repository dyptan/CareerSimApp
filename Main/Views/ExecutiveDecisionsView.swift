import SwiftUI

/// The **Boardroom** — the surface for senior-leadership strategy plays, shown
/// only while the player holds an executive seat (`Job.isExecutive`): a CEO,
/// director, partner, or founder. Each row is an optional `ExecutiveDecision`
/// resolved *immediately* on tap (unlike the deferred spare-time ventures),
/// mirroring the founder invest/sell flows. Making a play spends the year, so
/// the sheet closes on tap and the result arrives as a pop-up on the game view
/// (see `Player.reportApplicationOutcome`) and is banked into the status log.
///
/// Presented from `RootView`, gated by the "Boardroom" footer button.
struct ExecutiveDecisionsView: View {
    @ObservedObject var player: Player
    @Binding var showSheet: Bool
    /// Making a play spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// The asking price the player has dialled in on the Sell-Your-Stake slider,
    /// in dollars. `nil` until they touch it, so the slider seeds at fair value.
    @State private var askPrice: Double?

    private var roleName: String {
        player.currentOccupation.map { "\($0.icon) \($0.displayTitle)" } ?? "your seat"
    }

    var body: some View {
        NavigationStack { content }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    // Investment rounds are for scalable ventures only.
                    ForEach(ExecutiveDecisionCatalog.all.filter {
                        $0.kind != .investmentRound || player.canRaiseInvestmentRound
                    }) { decision in
                        card(for: decision)
                    }
                }
                .padding()
            }
        }
        .gameSheetClose($showSheet, title: "Boardroom")
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("🏛️ Boardroom")
                .font(.title2.bold())
            Text("Leading as \(roleName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text("💰 Savings: \(player.savings.formatted(.number)) $")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                InfoHint(
                    title: "🏛️ Boardroom",
                    message: "Optional strategic plays for the company you lead. Each can be made once a year, and making one spends the year."
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func card(for decision: ExecutiveDecision) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(decision.icon).font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.label).font(.headline)
                }
                Spacer(minLength: 0)
                InfoHint(title: "\(decision.icon) \(decision.label)", message: infoMessage(for: decision))
            }

            if decision.kind == .sellShares {
                sellControls
            } else {
                Text(previewLine(for: decision))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button {
                let result = decision.kind == .sellShares
                    ? player.resolveExecutiveDecision(decision, askPrice: currentAsk)
                    : player.resolveExecutiveDecision(decision)
                player.reportApplicationOutcome(
                    title: result.success ? "\(decision.icon) It worked" : "\(decision.icon) It didn't land",
                    message: resultLine(for: result)
                )
                onCommit()
            } label: {
                Text(actionLabel(for: decision))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Sell-your-stake controls

    /// The asking price currently dialled in, in dollars — the slider value, or
    /// fair value if the player hasn't touched it yet.
    private var currentAsk: Int {
        Int((askPrice ?? Double(player.shareStakeValue())).rounded())
    }

    /// Price slider plus a live read-out of the fair value and the odds a buyer
    /// takes the stake at the chosen price. Shown in place of the static preview
    /// line for the Sell-Your-Stake card.
    @ViewBuilder
    private var sellControls: some View {
        let bounds = player.shareAskingBounds()
        let odds = player.shareSaleOdds(askPrice: currentAsk)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Asking price")
                Spacer()
                Text("\(currentAsk.formatted(.number)) $").monospacedDigit()
            }
            .font(.caption.bold())

            if bounds.max > bounds.min {
                Slider(
                    value: Binding(
                        get: { askPrice ?? Double(bounds.fair) },
                        set: { askPrice = $0 }
                    ),
                    in: Double(bounds.min)...Double(bounds.max)
                )
            }

            Text("🏷️ Fair value \(bounds.fair.formatted(.number)) $ · 🎲 ~\(Int((odds * 100).rounded()))% a buyer bites\(player.economyInRecession ? " · 📉 recession" : "")")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy helpers

    private func actionLabel(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound: return "Announce the round"
        case .sellShares:      return "Offer for sale at \(currentAsk.formatted(.number)) $"
        }
    }

    private func previewLine(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            let famePts = Int((player.investmentRoundFameBonus() * 100).rounded())
            return "🎲 ~\(odds)% success (💼 fame +\(famePts)%) · 📈 stake ×\(String(format: "%.1f", GameConstants.investmentRoundValueGrowth)), pay +\(Int(((GameConstants.investmentRoundIncomeGrowth - 1) * 100).rounded()))%"
        case .sellShares:
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return "🎲 ~\(odds)% a buyer bites · 💰 \(currentAsk.formatted(.number)) $"
        }
    }

    private func resultLine(for outcome: ExecutiveDecision.Outcome) -> String {
        switch outcome.decision.kind {
        case .investmentRound:
            return outcome.success
                ? "🎉 Round closed — the company is worth more, it can pay you more, and you banked “\(outcome.fameTitle ?? "")” fame."
                : "🚫 Investors passed this time. Build your reputation and try again next year."
        case .sellShares:
            return outcome.success
                ? "💸 Sold — \(outcome.cash.formatted(.number)) $ added to your savings."
                : "🤝 No buyer at that price this year. Ask less, or try again next year."
        }
    }

    private func infoMessage(for decision: ExecutiveDecision) -> String {
        // The play's own pitch leads its hint; the card keeps only the numbers.
        decision.blurb + "\n\n" + infoDetails(for: decision)
    }

    private func infoDetails(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            let famePts = Int((player.investmentRoundFameBonus() * 100).rounded())
            return """
            A gamble. ~\(odds)% to close this year, driven by your pitch — 💬 Persuasion most of all, then vision, communication and leadership (worth +\(Int((player.investmentRoundSkillFit() * 40).rounded()))% of up to +40% right now) — your network, and above all your business (💼) fame: the market backs founders it has heard of. Your reputation is worth +\(famePts)% on the odds right now (up to +55%).

            The money goes into the company, not your pocket: your stake is worth ×\(String(format: "%.1f", GameConstants.investmentRoundValueGrowth)) even after the investors' share, the business can pay you \(Int(((GameConstants.investmentRoundIncomeGrowth - 1) * 100).rounded()))% more, and you bank business fame. Cash it in by selling your stake. Failure costs only the year's effort.
            """
        case .sellShares:
            let bounds = player.shareAskingBounds()
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return """
            Put your equity on the market at a price you name. Its fair value right now is \(bounds.fair.formatted(.number)) $ — \(player.currentOccupation?.isEntrepreneurial == true ? "the business's full income times its age (up to 2.5×, as small businesses sell), lifted by any investment rounds and a breakout" : "your pay times your tenure in the seat").

            The higher you ask, the fewer buyers: at \(currentAsk.formatted(.number)) $ there's roughly a \(odds)% chance one bites this year\(player.economyInRecession ? ", and a recession is thinning the pool right now" : "").

            Land a sale and, if you're a founder, you exit the venture — the seat and company are gone, freeing you to start something new.
            """
        }
    }
}

#Preview {
    ExecutiveDecisionsView(
        player: {
            let p = Player()
            p.currentOccupation = JobCatalog.allJobs().first { $0.id == "Chief Executive Officer" }
            return p
        }(),
        showSheet: .constant(true)
    )
}
