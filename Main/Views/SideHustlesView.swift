import SwiftUI

/// Lets the player pick which side hustles to attempt this year — monetizing the
/// talents they've built through hobbies and activities. Mirrors `ActivitiesView`:
/// the catalogue is filtered by life stage and capped per year, but here each row
/// also shows the upfront stake, the talent-driven success odds, and the upside.
struct SideHustlesView: View {
    @ObservedObject var player: Player
    @Binding var selectedSideHustles: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageHustles: [SideHustle] {
        SideHustleCatalog.all.filter { $0.stages.contains(currentStage) }
    }

    /// Capital already committed to the hustles picked this year.
    private var committedStake: Int {
        selectedSideHustles.reduce(0) { $0 + (SideHustleCatalog.byId[$1]?.startupCost ?? 0) }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Side hustles this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedSideHustles.count)/\(GameConstants.maxSideHustlesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedSideHustles.count >= GameConstants.maxSideHustlesPerYear
                            ? .red : .primary
                    )
            }
            Text("Monetize your talents · savings: \(player.savings.formatted(.number)) $")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageHustles) { hustle in
                        row(for: hustle)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for hustle: SideHustle) -> some View {
        let isSelected = selectedSideHustles.contains(hustle.id)
        let atLimit = selectedSideHustles.count >= GameConstants.maxSideHustlesPerYear
        // Whether the stake fits the savings still free after the other ventures
        // already picked this year. NOT a gate — an over-budget stake is taken on
        // credit (into debt); this only flags the stake label.
        let canAfford = player.savings - committedStake >= hustle.startupCost
        let isDisabled = !isSelected && atLimit

        let odds = Int((hustle.successProbability(for: player.softSkills) * 100).rounded())
        let upside = hustle.projectedPayout(for: player.softSkills)

        let pictos: String = hustle.talents
            .compactMap { skillPictogramByKeyPath[$0 as PartialKeyPath<SoftSkills>] }
            .joined(separator: " ")

        let hintMessage: String = hustle.talents
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
                            selectedSideHustles.insert(hustle.id)
                        } else {
                            selectedSideHustles.remove(hustle.id)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(hustle.icon)  \(hustle.label)")
                        .font(.headline)
                    Text(hustle.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Talents: \(pictos)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Text(hustle.startupCost == 0
                             ? "💵 No stake"
                             : (canAfford
                                ? "💵 Stake \(hustle.startupCost.formatted(.number)) $"
                                : "💵 Stake \(hustle.startupCost.formatted(.number)) $ (on credit)"))
                            .foregroundStyle(canAfford ? Color.secondary : Color.orange)
                        Text("🎲 ~\(odds)%")
                        Text("📈 up to \(upside.formatted(.number)) $")
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                atLimit && !isSelected
                    ? "You can take up to \(GameConstants.maxSideHustlesPerYear) side hustles this year."
                    : ""
            )

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: "Monetizes:\n\n\(hintMessage)\n\nBuild these talents through activities and hobbies to raise your odds and payout."
            )
        }
        .padding(5)
    }
}

#Preview {
    SideHustlesView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
