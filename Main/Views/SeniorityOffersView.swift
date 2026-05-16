import SwiftUI

/// Fourth level of the careers nav stack — once the player has picked a base
/// role and an employer tier, this screen lets them choose a seniority rung
/// (Junior, Senior, Staff, Principal, ...) before drilling into the
/// application screen. Only shown when a base role has multiple seniority
/// variants.
struct SeniorityOffersView: View {
    let variants: [Job]
    let tier: CompanyTier
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var baseTitle: String { variants.first?.baseTitle ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a seniority level at \(tier.displayName).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(Array(variants.enumerated()), id: \.offset) { _, variant in
                    let adjusted = variant.atTier(tier)
                    NavigationLink {
                        JobDetail(
                            job: adjusted,
                            player: player,
                            showCareersSheet: $showCareersSheet
                        )
                    } label: {
                        seniorityCard(for: adjusted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("\(baseTitle) — \(tier.displayName)")
    }

    @ViewBuilder
    private func seniorityCard(for offer: Job) -> some View {
        let prob = offer.hireProbability(for: player, requestedSalary: Double(offer.annualIncome))
        let probColor: Color = prob >= 0.6 ? .green : prob >= 0.3 ? .orange : .red
        let yearsRequired = offer.requirements.minYearsExperience
        let playerYears = player.experience[offer.category] ?? 0

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(offer.seniorityLabel)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }

            Text(offer.id)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Label("\(offer.annualIncome.formatted(.number)) $/yr", systemImage: "dollarsign.circle")
                    .font(.subheadline)
                if yearsRequired > 0 {
                    Label(
                        "\(yearsRequired) yr exp.",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(playerYears >= yearsRequired ? .secondary : .red)
                }
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
