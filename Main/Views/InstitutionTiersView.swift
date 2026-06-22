import SwiftUI

/// Third level of the education nav stack — picks the tier of the institution
/// (Community / State / Elite) for a chosen (level, profile) degree.
struct InstitutionTiersView: View {
    @ObservedObject var player: Player
    let level: Level.Stage
    let profile: TertiaryProfile

    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool

    private var tiers: [Education] {
        // Simplified mode has no institution tiers — a single neutral school
        // (community tier: no prestige bonus, lowest tuition, base admission bar).
        if player.isSimplified {
            return [Education(level, profile: profile, tier: .community)]
        }
        return EducationTier.allCases.map { Education(level, profile: profile, tier: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(tiers.enumerated()), id: \.element.id) { _, education in
                    tierCard(for: education)
                }
            }
            .padding()
        }
        .navigationTitle(player.isSimplified ? "Enroll" : "Compare schools")
    }

    @ViewBuilder
    private func tierCard(for education: Education) -> some View {
        let r = education.requirements
        let highestEQF = player.degrees.last?.eqf ?? 0
        let meetsAll = education.meetsRequirements(player: player)
        let canAfford = player.savings >= education.totalTuition

        VStack(alignment: .leading, spacing: 10) {
            if player.isSimplified {
                HStack(spacing: 6) {
                    Text("\(education.pictogram) \(education.degreeName)")
                        .font(.headline)
                    Spacer()
                }
            } else {
                HStack(spacing: 6) {
                    Text("\(education.tier.pictogram) \(education.tier.friendlyName)")
                        .font(.headline)
                    InfoHint(
                        title: "\(education.tier.pictogram) \(education.tier.friendlyName)",
                        message: education.tier.description
                    )
                    Spacer()
                    prestigeBadge(education.tier.prestige)
                }
            }

            HStack(spacing: 10) {
                Label("\(education.annualTuition.formatted(.number)) $/yr", systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundStyle(canAfford ? Color.secondary : Color.red)
                Label("Total \(education.totalTuition.formatted(.number)) $", systemImage: "sum")
                    .font(.caption)
                    .foregroundStyle(canAfford ? Color.secondary : Color.red)
                Label("\(education.yearsToComplete) yrs", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Admission requirements:")
                    .font(.subheadline.bold())
                    .padding(.top, 4)

                let eduMet = highestEQF >= r.minEQF
                RequirementRow(
                    label: r.educationLabel(),
                    emoji: "🎓",
                    style: .meter(current: highestEQF, required: r.minEQF)
                )
                .foregroundStyle(eduMet ? .primary : .secondary)

                ForEach(Education.Requirements.softSkillMappings) { mapping in
                    let required = r[keyPath: mapping.requirementKeyPath]
                    if required > 0 {
                        let playerValue = player.softSkills[keyPath: mapping.playerKeyPath]
                        RequirementRow(
                            label: mapping.id,
                            emoji: mapping.pictogram,
                            style: .meter(current: playerValue, required: required)
                        )
                        .foregroundStyle(playerValue >= required ? .primary : .secondary)
                    }
                }
            }

            Button {
                player.currentOccupation = nil
                player.currentEducation = education
                yearsLeftToGraduation = education.yearsToComplete
                showTertiarySheet = false
            } label: {
                Text(meetsAll ? "Enroll" : "Requirements not met")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!meetsAll)
            .opacity(meetsAll ? 1.0 : 0.5)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func prestigeBadge(_ prestige: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < prestige ? "star.fill" : "star")
                    .imageScale(.small)
                    .foregroundStyle(i < prestige ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
    }
}
