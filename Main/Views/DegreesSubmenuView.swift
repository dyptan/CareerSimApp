import SwiftUI

struct DegreesSubmenuView: View {
    @ObservedObject var player: Player
    let profile: TertiaryProfile
    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool

    private var degrees: [Education] {
        let availableEducations = availableNextEducations(holds: player.degrees)
        return availableEducations
            .filter { $0.profile == profile }
            .sorted { lhs, rhs in
                let order: [Level.Stage: Int] = [
                    .Vocational: 0, .Bachelor: 1, .Master: 2, .Doctorate: 3,
                ]
                return (order[lhs.level] ?? 99) < (order[rhs.level] ?? 99)
            }
    }

    var body: some View {
        List {
            ForEach(Array(degrees.enumerated()), id: \.element.id) { index, education in
                let r = education.requirements
                let highestEQF = player.degrees.last?.eqf ?? 0
                let meetsAll = education.meetsRequirements(player: player)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(education.degreeName)
                            .font(.headline)
                        Text("Takes \(education.yearsToComplete) years")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Requirements:")
                            .font(.subheadline.bold())

                        let eduMet = highestEQF >= r.minEQF
                        RequirementRow(
                            label: r.educationLabel(),
                            emoji: "🎓",
                            style: .meter(current: highestEQF, required: r.minEQF)
                        )
                        .foregroundStyle(eduMet ? .primary : .secondary)
                        .padding(.horizontal)

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
                                .padding(.horizontal)
                            }
                        }
                    }.padding(.top, 4)

                    Button {
                        player.currentOccupation = nil
                        player.currentEducation = education
                        yearsLeftToGraduation = education.yearsToComplete
                        showTertiarySheet = false
                    } label: {
                        Text("Apply").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!meetsAll)
                    .opacity(meetsAll ? 1.0 : 0.5)
                    .padding()
                }.padding(.vertical, 6)
            }
        }
        .navigationTitle(profile.rawValue.capitalized)
        .frame(minHeight: 400)
    }
}
