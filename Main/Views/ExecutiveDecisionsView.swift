import SwiftUI

/// The **Boardroom** — the surface for senior-leadership strategy plays, shown
/// only while the player holds an executive seat (`Job.isExecutive`): a CEO,
/// director, partner, or founder. Each row is an optional `ExecutiveDecision`
/// resolved *immediately* on tap (unlike the deferred spare-time ventures),
/// mirroring the founder invest/sell flows. A decision can be taken once per
/// year; the result is shown inline and banked into the status log.
///
/// Presented from `RootView`, gated by the "Boardroom" footer button.
struct ExecutiveDecisionsView: View {
    @ObservedObject var player: Player
    @Binding var showSheet: Bool

    /// The outcome of the most recent decision this session, shown inline under
    /// its row. Keyed by decision id so each row shows only its own result.
    @State private var outcomes: [String: ExecutiveDecision.Outcome] = [:]

    /// The asking price the player has dialled in on the Sell-Your-Stake slider,
    /// in dollars. `nil` until they touch it, so the slider seeds at fair value.
    @State private var askPrice: Double?

    private var roleName: String {
        player.currentOccupation.map { "\($0.icon) \($0.displayTitle)" } ?? "your seat"
    }

    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
            #if os(iOS)
                .navigationViewStyle(.stack)
            #endif
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ExecutiveDecisionCatalog.all) { decision in
                        card(for: decision)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Boardroom")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showSheet = false }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("🏛️ Boardroom")
                .font(.title2.bold())
            Text("Leading as \(roleName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Optional strategic plays — each can be made once a year · savings: \(player.savings.formatted(.number)) $")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func card(for decision: ExecutiveDecision) -> some View {
        let used = player.hasUsedExecutiveDecision(decision)
        let outcome = outcomes[decision.id]

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(decision.icon).font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.label).font(.headline)
                    Text(decision.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                InfoHint(title: "\(decision.icon) \(decision.label)", message: infoMessage(for: decision))
            }

            if !used {
                if decision.kind == .sellShares {
                    sellControls
                } else {
                    Text(previewLine(for: decision))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                let result = decision.kind == .sellShares
                    ? player.resolveExecutiveDecision(decision, askPrice: currentAsk)
                    : player.resolveExecutiveDecision(decision)
                outcomes[decision.id] = result
            } label: {
                Text(used ? "Done for this year" : actionLabel(for: decision))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(used)

            if let outcome {
                Text(resultLine(for: outcome))
                    .font(.callout.bold())
                    .foregroundStyle(outcome.success ? .green : .orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
            let upside = player.investmentRoundProjectedRaise()
            return "🎲 ~\(odds)% success (💼 fame +\(famePts)%) · 📈 up to \(upside.formatted(.number)) $"
        case .sellShares:
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return "🎲 ~\(odds)% a buyer bites · 💰 \(currentAsk.formatted(.number)) $"
        }
    }

    private func resultLine(for outcome: ExecutiveDecision.Outcome) -> String {
        switch outcome.decision.kind {
        case .investmentRound:
            return outcome.success
                ? "🎉 Round closed — raised \(outcome.cash.formatted(.number)) $ and banked “\(outcome.fameTitle ?? "")” fame."
                : "🚫 Investors passed this time. Build your reputation and try again next year."
        case .sellShares:
            return outcome.success
                ? "💸 Sold — \(outcome.cash.formatted(.number)) $ added to your savings."
                : "🤝 No buyer at that price this year. Ask less, or try again next year."
        }
    }

    private func infoMessage(for decision: ExecutiveDecision) -> String {
        let talents = decision.talents
            .compactMap { SoftSkills.label(forKeyPath: $0 as PartialKeyPath<SoftSkills>) }
            .joined(separator: ", ")
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            let famePts = Int((player.investmentRoundFameBonus() * 100).rounded())
            return """
            A gamble. ~\(odds)% to close this year, driven by your \(talents) and network — but above all by your business (💼) fame: the market backs founders it has heard of. Your reputation is worth +\(famePts)% on the odds right now (up to +55%).

            Success realises a raise worth up to \(player.investmentRoundProjectedRaise().formatted(.number)) $ as equity liquidity, banks more business fame, and sharpens your vision and persuasion. Failure costs only the year's effort.
            """
        case .sellShares:
            let bounds = player.shareAskingBounds()
            let odds = Int((player.shareSaleOdds(askPrice: currentAsk) * 100).rounded())
            return """
            Put your equity on the market at a price you name. Its fair value right now is \(bounds.fair.formatted(.number)) $ — pay and tenure in the seat, lifted by your venture's traction (revenue and market share).

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
