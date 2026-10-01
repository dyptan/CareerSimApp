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

    private var baseTitle: String { variants.first?.displayBaseTitle ?? "" }

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

    /// The rung's name ("Senior", "Lead"), or "Standard" for the bare role.
    private func seniorityName(of offer: Job) -> String {
        offer.displayRungLabel.isEmpty
            ? String(localized: "Standard", comment: "Seniority level of the plain version of a job, with no Junior/Senior/Lead prefix") // i18n:ignore translator comment
            : offer.displayRungLabel
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
                Text(seniorityName(of: offer))
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }

            Text(offer.catalogueTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Wraps onto a second line rather than clipping when the labels run long.
            HStack(spacing: 14) {
                Label(L("\(player.money(offer.annualIncome))/yr"), systemImage: "banknote")
                    .font(.subheadline)
                if yearsExpected > 0 {
                    Label(
                        L("\(yearsExpected) yr exp."),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(yearsColor)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            if player.isSimplified {
                HStack {
                    Text(qualifies ? L("✓ You can apply") : L("🔒 Not yet"))
                        .font(.caption.bold())
                        .foregroundStyle(qualifies ? Color.green : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            } else {
                HStack {
                    Text("Chance to get hired:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text(HintFmt.oddsPercent(prob))
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
