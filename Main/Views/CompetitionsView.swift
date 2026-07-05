import SwiftUI

/// Lets the player enter athletic and e-sports competitions this year. Mirrors
/// `SideHustlesView`: the catalogue is filtered by life stage and capped per
/// year. Each row shows the entry fee, the skill-driven win odds, the prize,
/// and the achievement a win earns — a reputation that boosts hiring across
/// Show Business (see `Player.fameHireBonus(for:)`). Entries are resolved at
/// year end in `Player.advanceYear`.
struct CompetitionsView: View {
    @ObservedObject var player: Player
    @Binding var selectedCompetitions: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// Stage-eligible competitions further filtered to ones the player
    /// qualifies for — at least one of their practised sports must overlap
    /// the competition's `sports` set (sport-agnostic competitions, with a
    /// nil `sports`, are always shown).
    private var stageCompetitions: [Competition] {
        CompetitionCatalog.all.filter { competition in
            guard competition.stages.contains(currentStage) else { return false }
            guard let sports = competition.sports else { return true }
            return sports.contains { player.sportYears[$0, default: 0] > 0 }
        }
    }

    /// Entry fees already committed to the competitions picked this year.
    private var committedFees: Int {
        selectedCompetitions.reduce(0) { $0 + (CompetitionCatalog.byId[$1]?.entryFee ?? 0) }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Competitions this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedCompetitions.count)/\(GameConstants.maxCompetitionsPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedCompetitions.count >= GameConstants.maxCompetitionsPerYear
                            ? .red : .primary
                    )
            }
            Text("🏆 \(player.achievements.count) achievement\(player.achievements.count == 1 ? "" : "s") · savings: \(player.savings.formatted(.number)) $")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageCompetitions) { competition in
                        row(for: competition)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for competition: Competition) -> some View {
        let isSelected = selectedCompetitions.contains(competition.id)
        let atLimit = selectedCompetitions.count >= GameConstants.maxCompetitionsPerYear
        let isDisabled = !isSelected && atLimit
        // A flag, not a gate — an unaffordable entry is taken on credit.
        let canAfford = player.savings - committedFees >= competition.entryFee
        let odds = Int((competition.winProbability(for: player.softSkills, sportYears: player.sportYears) * 100).rounded())

        let pictos: String = competition.skills
            .compactMap { skillPictogramByKeyPath[$0 as PartialKeyPath<SoftSkills>] }
            .joined(separator: " ")

        let hintMessage: String = competition.skills
            .map { kp -> String in
                let label = SoftSkills.label(forKeyPath: kp as PartialKeyPath<SoftSkills>) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp as PartialKeyPath<SoftSkills>] ?? ""
                return "\(pic) \(label)"
            }
            .joined(separator: "\n")

        HStack(alignment: .top, spacing: 8) {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn {
                            guard !atLimit else { return }
                            selectedCompetitions.insert(competition.id)
                        } else {
                            selectedCompetitions.remove(competition.id)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(competition.icon)  \(competition.name)")
                        .font(.headline)
                    Text("\(competition.discipline.rawValue) · \(competition.blurb)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !pictos.isEmpty {
                        Text("Skills: \(pictos)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        Text(canAfford
                             ? "💵 Entry \(competition.entryFee.formatted(.number)) $"
                             : "💵 Entry \(competition.entryFee.formatted(.number)) $ (on credit)")
                            .foregroundStyle(canAfford ? Color.secondary : Color.orange)
                        Text("🎲 ~\(odds)%")
                        Text("📈 \(competition.prize.formatted(.number)) $")
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    Text("🏅 Win: \(competition.achievement)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                atLimit && !isSelected
                    ? "You can enter up to \(GameConstants.maxCompetitionsPerYear) competitions this year."
                    : ""
            )

            InfoHint(
                title: "\(competition.icon) \(competition.name)",
                message: "Win odds rise with these skills:\n\n\(hintMessage)\n\nWinning pays \(competition.prize.formatted(.number)) $ and earns the “\(competition.achievement)” achievement, which boosts your hire odds across Show Business (ad, TV, music, sport, e-sports)."
            )
        }
        .padding(5)
    }
}

#Preview {
    CompetitionsView(
        player: Player(),
        selectedCompetitions: .constant([])
    )
    .padding()
}
