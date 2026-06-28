import SwiftUI

/// Lets the player commit this year's spare-time slot to training in a sport.
/// Sports share the same `selectedActivities` slot as hobbies, certifications,
/// and licenses, so picking one displaces any other activity. Each year of
/// practice banks into `Player.sportYears`, which (a) gates which competitions
/// appear in `CompetitionsView` and (b) adds a sport-fit bonus to the win
/// probability of qualifying competitions.
struct SportsView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSports: Set<Sport>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageSports: [Sport] {
        Sport.allCases.filter {
            $0.stages.contains(currentStage)
                && (!$0.isElite || player.difficulty == .comfortable)
        }
    }

    var body: some View {
        VStack {

            HStack(spacing: 6) {
                Text("Sport this year:")
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

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageSports) { sport in
                        row(for: sport)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for sport: Sport) -> some View {
        let pictos: String = sport.abilities
            .compactMap { ability -> String? in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return ability.weight > 1 ? "\(ability.weight)x\(pic)" : pic
            }
            .joined(separator: " ")

        let abilityHint: String = sport.abilities
            .map { ability -> String in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        let years = player.sportYears[sport, default: 0]
        let atLimit = selectedActivities.count >= GameConstants.maxHobbiesPerYear
        let isSelected = selectedSports.contains(sport)

        HStack(spacing: 8) {
            Toggle(
                "\(sport.pictogram) \(sport.label)\n\(pictos)\(years > 0 ? "  ·  \(years) yr\(years == 1 ? "" : "s") trained" : "")",
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn && !atLimit {
                            player.selectSport(sport, into: &selectedActivities, sports: &selectedSports)
                        } else if !isOn {
                            player.deselectSport(sport, from: &selectedActivities, sports: &selectedSports)
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
                    ? "You can train one activity per year — drop your current pick first."
                    : ""
            )
            .platformToggleStyle()

            InfoHint(
                title: "\(sport.pictogram) \(sport.label)",
                message: "\(sport.description)\n\nEach year of training builds:\n\n\(abilityHint)\n\nYears trained also unlock matching competitions and lift your win odds inside them."
            )
        }
        .padding(5)
    }
}

#Preview {
    SportsView(
        player: Player(),
        selectedActivities: .constant([]),
        selectedSports: .constant([])
    )
    .padding()
}
