import SwiftUI

/// The running-venture panel shown inside the **Ventures** surface while the
/// player operates an active startup (realistic mode only, see
/// `EntrepreneurshipView`). It reports the company's live valuation — traction-
/// and economy-adjusted (see `Player.ventureValuation`) — and lets the founder
/// sell any slice of their equity with a slider. Selling the whole stake exits
/// the venture; a partial sale banks the cash and keeps them running with a
/// smaller ownership share (`Player.sellVentureShares`). There are no buyout
/// offers — the founder sells on their own schedule.
struct ActiveVentureView: View {
    @ObservedObject var player: Player

    /// Fraction (0...1) of the founder's *current* stake to sell, driven by the
    /// slider. Resets to 0 after each sale.
    @State private var sellFraction: Double = 0

    private var title: String { player.currentOccupation?.baseTitle ?? "Your venture" }

    /// Whole-company valuation ($). Zero if the venture has somehow gone away.
    private var fullValuation: Int { player.ventureValuation ?? 0 }

    /// Cash value of the founder's retained stake ($).
    private var stakeValue: Int { player.founderStakeValue ?? 0 }

    private var ownershipPct: Int {
        Int(((player.activeStartup?.ownershipFraction ?? 0) * 100).rounded())
    }

    /// Cash the current slider position would bank.
    private var proceeds: Int { Int((Double(stakeValue) * sellFraction).rounded()) }

    private var sellPct: Int { Int((sellFraction * 100).rounded()) }

    /// Selling the entire remaining stake exits the venture.
    private var isFullExit: Bool { sellFraction >= 0.999 }

    private var valuationHint: String {
        """
        Your company's valuation is what the whole business is worth today. It starts from the capital your venture needs, multiplied for its tier (a bigger venture is worth a larger multiple), then scaled by how much traction you've built — your revenue versus that capital, plus your share of the market.

        The economy matters too: during a downturn, buyers and investors pay less, so valuations are marked down until the recession lifts.

        You own \(ownershipPct)% of the company. Selling shares banks that slice of the valuation as cash. Sell all of your shares and you exit the venture; sell only part and you keep running it with a smaller stake.
        """
    }

    @ViewBuilder
    private func metricsRow(for startup: ActiveStartup) -> some View {
        HStack(spacing: 18) {
            metric("📊", "\(Int(startup.marketSharePct.rounded()))%", "market")
            metric("💰", "\(startup.revenue.formatted(.number)) $", "revenue")
            metric("👥", "\(startup.headcount)", "staff")
        }
        .padding(.vertical, 4)
    }

    private func metric(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(icon) \(value)")
                .font(.callout.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("🏢 \(title)")
                    .font(.title2.bold())
                    .padding(.top)

                if let startup = player.activeStartup {
                    metricsRow(for: startup)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Company valuation")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        InfoHint(title: "How your venture is valued", message: valuationHint)
                    }
                    Text("\(fullValuation.formatted(.number)) $")
                        .font(.largeTitle.bold().monospacedDigit())
                        .foregroundStyle(.green)
                    Text("You own \(ownershipPct)% — worth \(stakeValue.formatted(.number)) $")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if player.economyInRecession {
                    Label("Recession — valuations are marked down until the economy recovers.",
                          systemImage: "chart.line.downtrend.xyaxis")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Divider()

                VStack(spacing: 10) {
                    HStack {
                        Text("Sell shares")
                            .font(.headline)
                        Spacer()
                        Text("\(sellPct)% of your stake")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $sellFraction, in: 0...1, step: 0.05)
                    Text(isFullExit
                         ? "You'll sell your entire stake and exit the venture."
                         : "You'll bank \(proceeds.formatted(.number)) $ and keep a \(ownershipPct - Int((Double(ownershipPct) * sellFraction).rounded()))% stake.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Button {
                    player.sellVentureShares(fractionOfStake: sellFraction)
                    sellFraction = 0
                } label: {
                    Text(isFullExit
                         ? "Sell entire stake for \(proceeds.formatted(.number)) $"
                         : "Sell \(sellPct)% for \(proceeds.formatted(.number)) $")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(sellFraction <= 0)
                .padding(.horizontal)
            }
            .padding(.bottom)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
