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

    private var roleName: String {
        player.currentOccupation.map { "\($0.icon) \($0.id)" } ?? "your seat"
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

            Text(previewLine(for: decision))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                let result = player.resolveExecutiveDecision(decision)
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

    // MARK: - Copy helpers

    private func actionLabel(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound: return "Announce the round"
        case .sellShares:      return "Sell shares for \(player.sellSharesPayout().formatted(.number)) $"
        }
    }

    private func previewLine(for decision: ExecutiveDecision) -> String {
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            let upside = player.investmentRoundProjectedRaise()
            return "🎲 ~\(odds)% success · 📈 up to \(upside.formatted(.number)) $ + 💼 business fame"
        case .sellShares:
            return "✅ Guaranteed · 💰 \(player.sellSharesPayout().formatted(.number)) $"
        }
    }

    private func resultLine(for outcome: ExecutiveDecision.Outcome) -> String {
        switch outcome.decision.kind {
        case .investmentRound:
            return outcome.success
                ? "🎉 Round closed — raised \(outcome.cash.formatted(.number)) $ and banked “\(outcome.fameTitle ?? "")” fame."
                : "🚫 Investors passed this time. Build your reputation and try again next year."
        case .sellShares:
            return "💸 Sold — \(outcome.cash.formatted(.number)) $ added to your savings."
        }
    }

    private func infoMessage(for decision: ExecutiveDecision) -> String {
        let talents = decision.talents
            .compactMap { SoftSkills.label(forKeyPath: $0 as PartialKeyPath<SoftSkills>) }
            .joined(separator: ", ")
        switch decision.kind {
        case .investmentRound:
            let odds = Int((player.investmentRoundOdds() * 100).rounded())
            return """
            A gamble. ~\(odds)% to close this year, driven by your \(talents), plus your network and reputation in the field.

            Success realises a raise worth up to \(player.investmentRoundProjectedRaise().formatted(.number)) $ as equity liquidity, banks industry fame, and sharpens your vision and persuasion. Failure costs only the year's effort.
            """
        case .sellShares:
            return """
            The safe play — no roll. You cash out vested equity for a guaranteed \(player.sellSharesPayout().formatted(.number)) $, scaled by your pay and the years you've held the seat.

            No fame, no headlines — just liquidity in the bank.
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
