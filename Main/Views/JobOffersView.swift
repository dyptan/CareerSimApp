import SwiftUI

/// Third level of the careers nav stack — shows multiple employer-tier offers
/// for the same job role so the player can compare salary, stability, and
/// hiring difficulty before drilling into the application screen.
struct JobOffersView: View {
    let job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var offers: [Job] {
        job.tieredOffers()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(job.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(Array(offers.enumerated()), id: \.offset) { _, offer in
                    NavigationLink {
                        JobDetail(
                            job: offer,
                            player: player,
                            showCareersSheet: $showCareersSheet
                        )
                    } label: {
                        offerCard(offer)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
        .navigationTitle(job.id)
    }

    @ViewBuilder
    private func offerCard(_ offer: Job) -> some View {
        let prob = offer.hireProbability(for: player, requestedSalary: Double(offer.annualIncome))
        let probColor: Color = prob >= 0.6 ? .green : prob >= 0.3 ? .orange : .red

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(offer.companyTier.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 14) {
                Label("\(offer.annualIncome.formatted(.number)) $/yr", systemImage: "dollarsign.circle")
                    .font(.subheadline)
                Label("\(Int(offer.companyTier.riskFactor * 100))% job-loss risk", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Hire chance at base salary:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(prob * 100)) %")
                    .font(.caption.bold())
                    .foregroundStyle(probColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
