import SwiftUI

/// Lets the player commit this year's spare-time slot to a club — a school
/// extracurricular or academic competition. Clubs share the same
/// `selectedActivities` slot as hobbies, sports, certifications, and
/// licenses, so picking one displaces any other activity. Most options are
/// gated to school stages; the dialog thins out naturally as the player
/// reaches adulthood, where Events / Side Hustles / Competitions take over.
struct ClubsView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageClubs: [Club] {
        clubs.filter { $0.stages.contains(currentStage) }
    }

    var body: some View {
        VStack {

            HStack(spacing: 6) {
                Text("Club this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedActivities.count)/\(GameConstants.maxHobbiesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedActivities.count >= GameConstants.maxHobbiesPerYear
                            ? .red : .primary
                    )
            }
            Text("\(currentStage.displayName) — age \(player.age)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            if stageClubs.isEmpty {
                Spacer()
                Text("No clubs at this stage of life — try Events, Side Projects, or Competitions instead.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(stageClubs, id: \.label) { club in
                            row(for: club)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for club: Club) -> some View {
        let pictos: String = club.abilities
            .compactMap { ability -> String? in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return ability.weight > 1 ? "\(ability.weight)x\(pic)" : pic
            }
            .joined(separator: " ")

        let abilityHint: String = club.abilities
            .map { ability -> String in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        let atLimit = selectedActivities.count >= GameConstants.maxHobbiesPerYear
        let isSelected = selectedActivities.contains(club.label)

        HStack(spacing: 8) {
            Toggle(
                "\(club.label)\n\(pictos)",
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn && !atLimit {
                            player.selectClub(club, into: &selectedActivities)
                        } else if !isOn {
                            player.deselectClub(club, from: &selectedActivities)
                        }
                    }
                )
            )
            .toggleStyle(.automatic)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(!isSelected && atLimit)
            .opacity((!isSelected && atLimit) ? 0.5 : 1.0)
            .help(
                (!isSelected && atLimit)
                    ? "You can take up to \(GameConstants.maxHobbiesPerYear) activities this year."
                    : ""
            )
            .platformToggleStyle()

            InfoHint(
                title: club.label,
                message: "Builds:\n\n\(abilityHint)"
            )
        }
        .padding(5)
    }
}

#Preview {
    ClubsView(
        player: Player(),
        selectedActivities: .constant([])
    )
    .padding()
}
