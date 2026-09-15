import SwiftUI

struct HobbiesView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>
    /// Choosing a hobby *is* choosing how the year goes, so this closes the
    /// sheet and runs the year. Default no-op keeps the preview simple.
    var onCommit: () -> Void = {}

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageHobbies: [Hobby] {
        hobbies.filter {
            $0.stages.contains(currentStage)
                && (!$0.isElite || player.difficulty == .comfortable)
        }
    }

    var body: some View {
        // No header strip: the sheet opens straight onto the hobbies. Tapping
        // **Take** on a row spends the year on it — the sheet closes and the
        // year runs — so there is no selection state to manage here.
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageHobbies, id: \.label) { hobby in
                        // One line per soft skill the hobby boosts, with the
                        // exact +N gain so the player knows what they're getting.
                        // The row itself stays clean — the skills live here, in
                        // the info hint.
                        let hintMessage: String = hobby.abilities
                            .map { ability -> String in
                                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                                return "\(pic) \(label) (+\(ability.weight))"
                            }
                            .joined(separator: "\n")

                        // Hobbies are repeatable — the same one can be practised
                        // every year to keep building its skills.
                        HStack(spacing: 8) {
                            Text(hobby.label)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            TakeButton {
                                player.selectHobby(hobby, into: &selectedActivities)
                                onCommit()
                            }

                            InfoHint(
                                title: hobby.label,
                                message: "Builds:\n\n\(hintMessage)"
                            )
                        }
                        .padding(5)
                    }

                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HobbiesView(
        player: Player(),
        selectedActivities: .constant([])
    )
    .padding()
}

