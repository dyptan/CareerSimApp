import SwiftUI

/// The unified **Private Projects** page. It lists money-making ventures
/// alongside portfolio projects in a single scroll. Both resolve as talent-fit
/// gambles that risk no money — the only difference is that a portfolio project
/// grants a portfolio piece instead of cash on success. Mirrors `HobbiesView`:
/// the catalogue is filtered by life stage and capped per year; each row shows
/// the talent-driven odds and, for money ventures, the upside.
struct PrivateProjectsView: View {
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

    /// Projects offered this stage. Portfolio pieces the player has already built
    /// are dropped — a finished piece can't be earned twice.
    private var stageProjects: [SideHustle] {
        SideHustleCatalog.all.filter { hustle in
            guard hustle.stages.contains(currentStage) else { return false }
            if let reward = hustle.portfolioReward, player.lockedPortfolio.contains(reward) {
                return false
            }
            return true
        }
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
            Text("Monetize your talents for cash · savings: \(player.savings.formatted(.number)) $")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageProjects) { hustle in
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
        let isDisabled = !isSelected && atLimit

        let odds = Int((hustle.successProbability(for: player.softSkills, fameScore: player.fameScore) * 100).rounded())
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
                        if hustle.isPortfolioProject {
                            Text("🎲 ~\(odds)%")
                            Text("📁 builds portfolio")
                        } else {
                            Text("🎲 ~\(odds)%")
                            Text("📈 up to \(upside.formatted(.number)) $")
                        }
                        if hustle.buildsFame {
                            Text("🌟 Fame")
                                .foregroundStyle(.purple)
                        }
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
                    ? "You can take up to \(GameConstants.maxSideHustlesPerYear) side hustle(s) this year."
                    : ""
            )

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: (hustle.isPortfolioProject
                    ? "Builds on:\n\n\(hintMessage)\n\nA private project risks no money — build these talents through activities and hobbies to raise the odds it comes together into a portfolio piece."
                    : "Monetizes:\n\n\(hintMessage)\n\nBuild these talents through activities and hobbies to raise your odds and payout.")
                    + (hustle.buildsFame
                        ? "\n\n🌟 A successful year earns the “\(hustle.fameAward ?? "")” trophy — fame that boosts your hire odds across Show Business (ad, TV, music, sport, e-sports)."
                        : "")
            )
        }
        .padding(5)
    }
}

#Preview {
    PrivateProjectsView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
