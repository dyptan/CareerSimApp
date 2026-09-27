import SwiftUI

/// Third level of the careers nav stack — once the player has picked a base
/// role, this screen lets them choose a seniority rung (Junior, Senior, Staff,
/// Principal, ...) before drilling into the application screen. Only shown when
/// a base role has multiple seniority variants.
struct SeniorityOffersView: View {
    let variants: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    var onCommit: () -> Void = {}

    private var baseTitle: String { variants.first?.baseTitle ?? "" }

    private var navTitle: String { baseTitle }

    /// The given variant priced at its base salary (deterministic, comparable).
    private func offer(for variant: Job) -> Job {
        variant.atBaseSalary()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(variants.enumerated()), id: \.offset) { _, variant in
                    let adjusted = offer(for: variant)
                    NavigationLink {
                        JobDetail(
                            job: adjusted,
                            player: player,
                            showCareersSheet: $showCareersSheet,
                            onCommit: onCommit
                        )
                    } label: {
                        seniorityCard(for: adjusted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle(navTitle)
    }

    @ViewBuilder
    private func seniorityCard(for offer: Job) -> some View {
        let prob = offer.hireProbability(for: player, requestedSalary: Double(offer.offeredSalary(for: player)))
        let probColor = Color.forOdds(prob)
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
                    Text(qualifies ? "✓ You can apply" : "🔒 Not yet")
                        .font(.caption.bold())
                        .foregroundStyle(qualifies ? Color.green : Color.secondary)
                    Spacer()
                }
            } else {
                HStack {
                    Text("Chance to get hired:")
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
