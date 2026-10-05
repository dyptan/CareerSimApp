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
    /// in the player's currency. `nil` until they touch it, so the slider seeds
    /// at fair value.
    @State private var askPrice: Double?

    /// "Leading as 💼 Chief Executive Officer" — a whole sentence per case.
    private var leadingLine: String {
        guard let job = player.currentOccupation else { return L("Leading as your seat") }
        return L("Leading as \(job.icon) \(job.displayTitle)")
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
        .gameSheetClose($showSheet, title: String(localized: "Boardroom", comment: "Title of the sheet with the senior-leadership plays (investment round, selling your stake)"))  // i18n:ignore translator comment
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("🏛️ Boardroom")
                .font(.title2.bold())
            Text(leadingLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(L("💰 Savings: \(player.money(player.savings))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                InfoHint(
                    title: "🏛️ Boardroom",
                    message: L("Big moves for the company you lead. You can make each one once a year, and making one uses up your year.")
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
                    title: result.success ? L("\(decision.icon) It worked!") : L("\(decision.icon) Not this time"),
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

    /// The asking price currently dialled in, in the player's currency — the
    /// slider value, or fair value if the player hasn't touched it yet.
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
                Text(verbatim: player.money(currentAsk)).monospacedDigit()
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

            Text(askingSummary(fair: bounds.fair, odds: odds))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy helpers

    /// "Worth about $X · 🎲 ~12% chance someone buys" — with the economy's mark when it is bad.
    private func askingSummary(fair: Int, odds: Double) -> String {
        player.economyInRecession
            ? L("🏷️ Worth about \(player.money(fair)) · 🎲 ~\(Fmt.percent(odds)) chance someone buys · 📉 bad economy")
            : L("🏷️ Worth about \(player.money(fair)) · 🎲 ~\(Fmt.percent(odds)) chance someone buys")
    }

    private func actionLabel(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound: return L("Announce the round")
        case .sellShares:      return L("Offer for sale at \(player.money(currentAsk))")
        }
    }

    private func previewLine(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            return L("🎲 ~\(Fmt.percent(player.investmentRoundOdds())) chance (💼 fame +\(Fmt.percent(player.investmentRoundFameBonus()))) · 📈 your share ×\(Fmt.decimal(GameConstants.investmentRoundValueGrowth)), pay +\(Fmt.percent(GameConstants.investmentRoundIncomeGrowth - 1))")
        case .sellShares:
            return L("🎲 ~\(Fmt.percent(player.shareSaleOdds(askPrice: currentAsk))) chance someone buys · 💰 \(player.money(currentAsk))")
        }
    }

    private func resultLine(for outcome: ExecutiveDecision.Outcome) -> String {
        switch outcome.decision.kind {
        case .investmentRound:
            return outcome.success
                ? L("🎉 Investors said yes! The company is worth more, it can pay you more, and you earned the “\(outcome.fameTitle ?? "")” title.")
                : L("🚫 Investors said no this time. Grow your reputation and try again next year.")
        case .sellShares:
            return outcome.success
                ? L("💸 Sold! \(player.money(outcome.cash)) went into your savings.")
                : L("🤝 Nobody bought at that price this year. Ask for less, or try again next year.")
        }
    }

    private func infoMessage(for decision: ExecutiveDecision) -> String {
        // The play's own pitch leads its hint; the card keeps only the numbers.
        decision.blurb + "\n\n" + infoDetails(for: decision)
    }

    /// The numbers behind a play, one paragraph per key.
    private func infoDetails(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            let rounds = GameConstants.maxInvestmentRounds
            let helps = [
                L("What helps:"),
                L("• Your pitch — 💬 Persuader most of all, then vision, talking and leading (+\(Fmt.percent(player.investmentRoundSkillFit() * 0.4)) now, up to +40%)"),
                L("• People you know"),
                L("• Your 💼 Business fame — investors back founders they've heard of (+\(Fmt.percent(player.investmentRoundFameBonus())) now, up to +25%)"),
            ].joined(separator: "\n")
            return [
                L("A gamble: about a \(Fmt.percent(player.investmentRoundOdds())) chance investors say yes this year."),
                helps,
                L("A company can raise money at most \(rounds) times, and investors want to see a year in business first."),
                L("The money goes into the company, not your pocket. Your share of the company becomes worth ×\(Fmt.decimal(GameConstants.investmentRoundValueGrowth)), the business can pay you \(Fmt.percent(GameConstants.investmentRoundIncomeGrowth - 1)) more, and you get more famous in business. To turn it into money, sell your share. If investors say no, you only lose the year."),
            ].joined(separator: "\n\n")
        case .sellShares:
            let fair = player.money(player.shareAskingBounds().fair)
            let ask = player.money(currentAsk)
            let odds = Fmt.percent(player.shareSaleOdds(askPrice: currentAsk))
            let founder = player.currentOccupation?.isEntrepreneurial == true
            let worth = founder
                ? L("Sell your share of the company for a price you choose. It's worth about \(fair) right now — what the business earns in a year times how long it's been running (up to 2.5×), plus any money raised from investors.")
                : L("Sell your share of the company for a price you choose. It's worth about \(fair) right now — the company shares you've earned since you last sold (part of your pay each year, up to twice your pay).")
            let buyers = player.economyInRecession
                ? L("The more you ask, the fewer buyers: at \(ask) there's about a \(odds) chance someone buys this year — fewer buyers than usual, because the economy is doing badly.")
                : L("The more you ask, the fewer buyers: at \(ask) there's about a \(odds) chance someone buys this year.")
            let aftermath = founder
                ? L("If it sells, you leave the business — it isn't yours any more, and you're free to start something new. Fees and taxes take \(Fmt.percent(GameConstants.founderExitCostRate)) of the price.")
                : L("If it sells, you keep your job. Taxes take \(Fmt.percent(GameConstants.equitySaleTaxRate)) of the price, and you start earning new shares from zero.")
            return [worth, buyers, aftermath].joined(separator: "\n\n")
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
