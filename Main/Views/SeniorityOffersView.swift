import SwiftUI

/// Fourth level of the careers nav stack — once the player has picked a base
/// role and an employer tier, this screen lets them choose a seniority rung
/// (Junior, Senior, Staff, Principal, ...) before drilling into the
/// application screen. Only shown when a base role has multiple seniority
/// variants.
struct SeniorityOffersView: View {
    let variants: [Job]
    /// The chosen employer tier, or `nil` in simplified mode (no company tiers).
    let tier: CompanyTier?
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var baseTitle: String { variants.first?.baseTitle ?? "" }

    private var headerText: String {
        if let tier {
            return "Choose a seniority level at \(tier.displayName)."
        }
        return "Choose a seniority level."
    }

    private var navTitle: String {
        if let tier { return "\(baseTitle) — \(tier.displayName)" }
        return baseTitle
    }

    /// The given variant priced for this screen's context: tier-adjusted in
    /// realistic mode, or at base salary in simplified mode.
    private func offer(for variant: Job) -> Job {
        if let tier { return variant.atTier(tier) }
        return variant.atBaseSalary()
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
        let yearsRequired = offer.requirements.minYearsExperience
        let playerYears = player.experience[offer.category] ?? 0
        let yearsColor: Color = playerYears >= yearsRequired ? .secondary : .red

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
