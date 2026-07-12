import SwiftUI

/// Sell-or-Hold dialog that appears the year a player's active startup lands a
/// buyout offer (see `Player.advanceYear` and `Player.activeStartup`). The
/// player either banks the cash (`acceptStartupOffer`) and exits the venture,
/// or declines and advances to the next founder rung (`holdStartup`). The
/// sheet is presented from `RootView`, driven by `Player.showStartupOfferSheet`.
struct StartupOfferView: View {
    @ObservedObject var player: Player

    private var rungTitle: String {
        guard let idx = player.activeStartup?.rungIndex,
              FounderLadder.rungTitles.indices.contains(idx) else {
            return player.currentOccupation?.baseTitle ?? "Your venture"
        }
        return FounderLadder.rungTitles[idx]
    }

    /// The next rung's title if there is one above the current rung. Used in
    /// the Hold-button copy so the player sees exactly what they're trading
    /// the cash offer for ("Hold & grow into Small Business Owner").
    private var nextRungTitle: String? {
        guard let idx = player.activeStartup?.rungIndex else { return nil }
        let next = idx + 1
        guard FounderLadder.rungTitles.indices.contains(next) else { return nil }
        return FounderLadder.rungTitles[next]
    }

    private var offerText: String {
        guard let offer = player.pendingStartupOffer else { return "—" }
        return "\(offer.formatted(.number)) $"
    }

    /// The venture's current business metrics — the traction that drove this
    /// offer up (see `ActiveStartup.exitPremium`).
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
        VStack(spacing: 18) {
            Text("💼 Buyout Offer")
                .font(.title2.bold())
                .padding(.top)

            Text("An acquirer wants to buy your \(rungTitle).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(offerText)
                .font(.largeTitle.bold())
                .foregroundStyle(.green)

            if let startup = player.activeStartup {
                metricsRow(for: startup)
            }

            Text(nextRungTitle == nil
                 ? "You're already at the top of the founder ladder. Hold and another bidder may show up next year."
                 : "Take the cash now, or hold and grow the company into \(nextRungTitle!) — bigger risk, bigger exit.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                player.acceptStartupOffer()
            } label: {
                Text("Sell for \(offerText)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                player.holdStartup()
            } label: {
                Text(nextRungTitle.map { "Hold & grow into \($0)" } ?? "Hold & wait for a better offer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
        #endif
    }
}
