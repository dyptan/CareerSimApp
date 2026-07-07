import SwiftUI

/// The unified **Projects** page — the single home for spare-time ventures,
/// joining what were two features (money-making side hustles and fame-earning
/// projects). Every row is a talent-fit gamble that stakes no money: most
/// ventures bank industry-scoped **fame** (and grow the soft skills they drew
/// on), while a handful of business plays still pay **cash**. Mirrors
/// `HobbiesView`: the catalogue is filtered by life stage and capped per year.
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

    /// Ventures offered this stage. All are always available once the player is
    /// old enough — no hobby prerequisite.
    private var stageProjects: [SideHustle] {
        SideHustleCatalog.all.filter { $0.stages.contains(currentStage) }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Projects this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedSideHustles.count)/\(GameConstants.maxSideHustlesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedSideHustles.count >= GameConstants.maxSideHustlesPerYear
                            ? .red : .primary
                    )
            }
            Text("Spend a year building fame — or banking cash · savings: \(player.savings.formatted(.number)) $")
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
        // A venture is locked until its relevant soft-skill prerequisite is met.
        let meetsPrereq = hustle.meetsPrerequisite(for: player.softSkills)
        let isDisabled = (!isSelected && atLimit) || !meetsPrereq

        let lockLabel: String? = {
            guard let req = hustle.prerequisite, !meetsPrereq else { return nil }
            let kp = req.keyPath as PartialKeyPath<SoftSkills>
            let pic = skillPictogramByKeyPath[kp] ?? ""
            let label = SoftSkills.label(forKeyPath: kp) ?? "skill"
            return "🔒 Requires \(pic) \(label) \(req.minLevel)"
        }()

        let odds = Int((hustle.successProbability(for: player.softSkills, fameScore: player.fameScore) * 100).rounded())
        let upside = hustle.projectedPayout(for: player.softSkills)

        let pictos: String = hustle.talents
            .compactMap { skillPictogramByKeyPath[$0 as PartialKeyPath<SoftSkills>] }
            .joined(separator: " ")

        // Soft skills a successful fame year grows (empty for money ventures).
        let growthPictos: String = hustle.growth
            .compactMap { boost -> String? in
                let kp = boost.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return "\(pic)+\(boost.weight)"
            }
            .joined(separator: " ")

        let talentHint: String = hustle.talents
            .map { kp -> String in
                let label = SoftSkills.label(forKeyPath: kp as PartialKeyPath<SoftSkills>) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp as PartialKeyPath<SoftSkills>] ?? ""
                return "\(pic) \(label)"
            }
            .joined(separator: "\n")

        let growthHint: String = hustle.growth
            .map { boost -> String in
                let kp = boost.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) +\(boost.weight)"
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
                    Text("Draws on: \(pictos)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if !growthPictos.isEmpty {
                        Text("Grows: \(growthPictos)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        Text("🎲 ~\(odds)%")
                        if let industry = hustle.fameIndustry {
                            Text("🌟 \(JobCategory.icon(for: industry)) \(industry.rawValue) fame")
                                .foregroundStyle(.purple)
                        } else {
                            Text("📈 up to \(upside.formatted(.number)) $")
                        }
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    if let lockLabel {
                        Text(lockLabel)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                !meetsPrereq
                    ? "Build the required soft skill first — take it on once you meet the prerequisite."
                    : (atLimit && !isSelected
                        ? "You can take on up to \(GameConstants.maxSideHustlesPerYear) project(s) this year."
                        : "")
            )

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: infoMessage(for: hustle, talentHint: talentHint, growthHint: growthHint)
            )
        }
        .padding(5)
    }

    private func infoMessage(for hustle: SideHustle, talentHint: String, growthHint: String) -> String {
        let gate: String = {
            guard let req = hustle.prerequisite else { return "" }
            let kp = req.keyPath as PartialKeyPath<SoftSkills>
            let pic = skillPictogramByKeyPath[kp] ?? ""
            let label = SoftSkills.label(forKeyPath: kp) ?? "a skill"
            return "🔒 Unlocks at \(pic) \(label) \(req.minLevel) — build it through hobbies first.\n\n"
        }()
        switch hustle.payoff {
        case .money:
            return gate + "Monetizes:\n\n\(talentHint)\n\nA money venture risks no cash — build these talents through activities and hobbies to raise your odds and payout. A flop simply earns nothing."
        case .fame(let industry, _):
            return gate + "Draws on:\n\n\(talentHint)\n\nA fame venture spends the soft skills you've built for a shot at being noticed. A successful year banks fame in \(JobCategory.icon(for: industry)) \(industry.rawValue) (industry-specific — it only helps you land \(industry.rawValue) roles) and grows you the way a hobby can't:\n\n\(growthHint)\n\nThe odds also climb with your existing reputation. A dud year yields nothing."
        }
    }
}

#Preview {
    PrivateProjectsView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
