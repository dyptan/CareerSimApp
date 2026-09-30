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
                    // Investment rounds are for scalable ventures only, and a
                    // stake sale needs something vested to sell.
                    ForEach(ExecutiveDecisionCatalog.all.filter {
                        ($0.kind != .investmentRound || player.canRaiseInvestmentRound)
                            && ($0.kind != .sellShares || player.shareStakeValue() > 0)
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
                Text("💰 Savings: \(player.money(player.savings))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                InfoHint(
                    title: "🏛️ Boardroom",
                    message: "Big moves for the company you lead. You can make each one once a year, and making one uses up your year."
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
                    title: result.success ? "\(decision.icon) It worked!" : "\(decision.icon) Not this time",
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
                Text("\(player.money(currentAsk))").monospacedDigit()
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

            Text("🏷️ Worth about \(player.money(bounds.fair)) · 🎲 ~\(Int((odds * 100).rounded()))% chance someone buys\(player.economyInRecession ? " · 📉 bad economy" : "")")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy helpers

    private func actionLabel(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound: return "Announce the round"
        case .sellShares:      return "Offer for sale at \(player.money(currentAsk))"
        }
    }

    private func previewLine(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            let famePts = Int((player.investmentRoundFameBonus() * 100).rounded())
            return "🎲 ~\(odds)% chance (💼 fame +\(famePts)%) · 📈 your share ×\(String(format: "%.1f", GameConstants.investmentRoundValueGrowth)), pay +\(Int(((GameConstants.investmentRoundIncomeGrowth - 1) * 100).rounded()))%"
        case .sellShares:
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return "🎲 ~\(odds)% chance someone buys · 💰 \(player.money(currentAsk))"
        }
    }

    private func resultLine(for outcome: ExecutiveDecision.Outcome) -> String {
        switch outcome.decision.kind {
        case .investmentRound:
            return outcome.success
                ? "🎉 Investors said yes! The company is worth more, it can pay you more, and you earned the “\(outcome.fameTitle ?? "")” title."
                : "🚫 Investors said no this time. Grow your reputation and try again next year."
        case .sellShares:
            return outcome.success
                ? "💸 Sold! \(player.money(outcome.cash)) went into your savings."
                : "🤝 Nobody bought at that price this year. Ask for less, or try again next year."
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
            A gamble: about a \(odds)% chance investors say yes this year.

            What helps:
            • Your pitch — 💬 Persuader most of all, then vision, talking and leading (+\(Int((player.investmentRoundSkillFit() * 40).rounded()))% now, up to +40%)
            • People you know
            • Your 💼 Business fame — investors back founders they've heard of (+\(famePts)% now, up to +25%)

            A company can raise money at most \(GameConstants.maxInvestmentRounds) times, and investors want to see a year in business first.

            The money goes into the company, not your pocket. Your share of the company becomes worth ×\(String(format: "%.1f", GameConstants.investmentRoundValueGrowth)), the business can pay you \(Int(((GameConstants.investmentRoundIncomeGrowth - 1) * 100).rounded()))% more, and you get more famous in business. To turn it into money, sell your share. If investors say no, you only lose the year.
            """
        case .sellShares:
            let bounds = player.shareAskingBounds()
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return """
            Sell your share of the company for a price you choose. It's worth about \(player.money(bounds.fair)) right now — \(player.currentOccupation?.isEntrepreneurial == true ? "what the business earns in a year times how long it's been running (up to 2.5×), plus any money raised from investors" : "the company shares you've earned since you last sold (part of your pay each year, up to twice your pay)").

            The more you ask, the fewer buyers: at \(player.money(currentAsk)) there's about a \(odds)% chance someone buys this year\(player.economyInRecession ? " — fewer buyers than usual, because the economy is doing badly" : "").

            \(player.currentOccupation?.isEntrepreneurial == true ? "If it sells, you leave the business — it isn't yours any more, and you're free to start something new. Fees and taxes take \(Int((GameConstants.founderExitCostRate * 100).rounded()))% of the price." : "If it sells, you keep your job. Taxes take \(Int((GameConstants.equitySaleTaxRate * 100).rounded()))% of the price, and you start earning new shares from zero.")
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
