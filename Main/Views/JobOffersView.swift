import SwiftUI

/// Third level of the careers nav stack — shows the plausible employer tiers
/// for a base role so the player can compare salary, stability, and hiring
/// difficulty. Picking a tier drills into either the seniority chooser (if
/// the role has multiple seniority variants) or directly into the application
/// screen (if it has only one).
struct JobOffersView: View {
    let variants: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    /// The least-senior variant is used as the reference for the role's
    /// plausible tier set and the summary/icon at the top of the screen.
    private var reference: Job { variants.first ?? variants[0] }

    private var hasMultipleSeniorities: Bool { variants.count > 1 }

    private var plausibleTiers: [CompanyTier] {
        // Union plausible tiers across every seniority variant so the player
        // sees the full range of employers that hire any rung of this ladder.
        var seen: Set<CompanyTier> = []
        var ordered: [CompanyTier] = []
        for v in variants {
            for tier in CompanyTier.plausibleTiers(category: v.category, income: v.income) {
                if seen.insert(tier).inserted { ordered.append(tier) }
            }
        }
        return ordered
    }

    /// Salary range across all seniority variants for the given tier.
    private func salaryRange(at tier: CompanyTier) -> (min: Int, max: Int) {
        let salaries = variants.map { Int(Double($0.income) * tier.salaryMultiplier) }
        return (salaries.min() ?? 0, salaries.max() ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(reference.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(Array(plausibleTiers.enumerated()), id: \.offset) { _, tier in
                    NavigationLink {
                        if hasMultipleSeniorities {
                            SeniorityOffersView(
                                variants: variants,
                                tier: tier,
                                player: player,
                                showCareersSheet: $showCareersSheet
                            )
                        } else {
                            JobDetail(
                                job: reference.atTier(tier),
                                player: player,
                                showCareersSheet: $showCareersSheet
                            )
                        }
                    } label: {
                        offerCard(for: tier)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
        .navigationTitle(reference.baseTitle)
    }

    @ViewBuilder
    private func offerCard(for tier: CompanyTier) -> some View {
        let range = salaryRange(at: tier)
        let salaryText: String = {
            if range.min == range.max {
                return "\(range.min.formatted(.number)) $/yr"
            }
            return "\(range.min.formatted(.number))–\(range.max.formatted(.number)) $/yr"
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tier.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 14) {
                Label(salaryText, systemImage: "dollarsign.circle")
                    .font(.subheadline)
                Label("\(Int(tier.riskFactor * 100))% job-loss risk", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if hasMultipleSeniorities {
                Text("\(variants.count) seniority levels available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let offer = reference.atTier(tier)
                let prob = offer.hireProbability(for: player, requestedSalary: Double(offer.annualIncome))
                let probColor: Color = prob >= 0.6 ? .green : prob >= 0.3 ? .orange : .red
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
