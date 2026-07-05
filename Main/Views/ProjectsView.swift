import SwiftUI

/// The **Projects** page — a deliberate mirror of `HobbiesView`, but inverted.
/// A hobby reliably *grants* soft skills for free; a project *spends* the soft
/// skills you've already built and gambles them on one reward a hobby can never
/// give: fame and recognition. Each row shows which soft skills are considered
/// (with the level each is measured against), the odds the year gets noticed,
/// and the fame it can earn (0, 1, or 2). Projects are repeatable and filtered
/// by life stage, exactly like hobbies.
struct ProjectsView: View {
    @ObservedObject var player: Player
    @Binding var selectedProjects: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// Projects offered this stage. A project only shows once the player has
    /// practised a hobby that unlocks it. Projects are repeatable — a player can
    /// chase the same stage again each year for another shot at recognition.
    private var stageProjects: [Project] {
        let unlocked = Project.unlocked(byPractisedHobbies: player.lockedHobbies)
        return Project.allCases.filter {
            $0.stages.contains(currentStage) && unlocked.contains($0)
        }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Projects this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedProjects.count)/\(GameConstants.maxProjectsPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedProjects.count >= GameConstants.maxProjectsPerYear
                            ? .red : .primary
                    )
            }
            Text("Spend your soft skills for fame and recognition — \(currentStage.displayName), age \(player.age)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageProjects) { project in
                        row(for: project)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for project: Project) -> some View {
        let isSelected = selectedProjects.contains(project.rawValue)
        let atLimit = selectedProjects.count >= GameConstants.maxProjectsPerYear
        let isDisabled = !isSelected && atLimit

        let odds = Int((project.successProbability(for: player.softSkills) * 100).rounded())

        // Each considered axis as "Nx🔍" (measured against level N) — mirrors how
        // a hobby row shows its weighted gains, but read as a skill drawn on
        // rather than a gain.
        let requirementPictos: String = project.requirements
            .compactMap { req -> String? in
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return req.weight > 1 ? "\(req.weight)x\(pic)" : pic
            }
            .joined(separator: " ")

        let requirementHint: String = project.requirements
            .map { req -> String in
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) (measured against \(req.weight))"
            }
            .joined(separator: "\n")

        HStack(alignment: .top, spacing: 8) {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn {
                            guard !atLimit else { return }
                            selectedProjects.insert(project.rawValue)
                        } else {
                            selectedProjects.remove(project.rawValue)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(project.pictogram)  \(project.rawValue)")
                        .font(.headline)
                    Text("Draws on: \(requirementPictos)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Text("🎲 ~\(odds)%")
                        Text("🌟 +0–1 \(JobCategory.icon(for: project.fameIndustry)) \(project.fameIndustry.rawValue) fame")
                            .foregroundStyle(.purple)
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
                isDisabled
                    ? "You can take up to \(GameConstants.maxProjectsPerYear) project(s) this year."
                    : ""
            )

            InfoHint(
                title: "\(project.pictogram) \(project.rawValue)",
                message: "\(project.description)\n\nSoft skills considered:\n\n\(requirementHint)\n\nUnlike a hobby, a project spends the soft skills you've built — the better you meet these, the likelier the year gets noticed. A noticed year earns +1 fame in \(JobCategory.icon(for: project.fameIndustry)) \(project.fameIndustry.rawValue), a dud nothing. Fame is industry-specific: it only helps you land \(project.fameIndustry.rawValue) roles."
            )
        }
        .padding(5)
    }
}

#Preview {
    ProjectsView(
        player: Player(),
        selectedProjects: .constant([])
    )
    .padding()
}
