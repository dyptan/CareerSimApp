import SwiftUI

/// Third level of the careers nav stack — once the player has picked a base
/// role, this screen lets them choose a seniority rung (Junior, Senior, Staff,
/// Principal, ...) before drilling into the application screen. Only shown when
/// a base role has multiple seniority variants.
struct SeniorityOffersView: View {
    let variants: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var baseTitle: String { variants.first?.baseTitle ?? "" }

    private var headerText: String { "Choose a seniority level." }

    private var navTitle: String { baseTitle }

    /// The given variant priced at its base salary (deterministic, comparable).
    private func offer(for variant: Job) -> Job {
        variant.atBaseSalary()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(headerText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(Array(variants.enumerated()), id: \.offset) { _, variant in
                    let adjusted = offer(for: variant)
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
        .navigationTitle(navTitle)
    }

    @ViewBuilder
    private func seniorityCard(for offer: Job) -> some View {
        let prob = offer.hireProbability(for: player, requestedSalary: Double(offer.annualIncome))
        let probColor: Color = prob >= 0.6 ? .green : prob >= 0.3 ? .orange : .red
        let qualifies = offer.allRequirementsMet(for: player)
        let yearsExpected = player.isSimplified ? offer.requirements.minYearsExperience : offer.expectedYearsExperience
        let playerYears = offer.relevantYears(for: player)
        let yearsColor: Color = playerYears >= yearsExpected ? .secondary : (player.isSimplified ? .red : .orange)

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
                if yearsExpected > 0 {
                    Label(
                        "\(yearsExpected) yr exp.",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(yearsColor)
                }
            }

            if player.isSimplified {
                HStack {
                    Text(qualifies ? "✓ You qualify" : "🔒 Not yet")
                        .font(.caption.bold())
                        .foregroundStyle(qualifies ? Color.green : Color.secondary)
                    Spacer()
                }
            } else {
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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
