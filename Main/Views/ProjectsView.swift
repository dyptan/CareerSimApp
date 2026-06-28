import SwiftUI

/// The **Projects** page — a deliberate mirror of `HobbiesView`, but inverted.
/// A hobby reliably *grants* soft skills for free; a project *spends* the soft
/// skills you've already built and gambles them on a deliverable. Each row shows
/// what the project *requires* (soft-skill axes, with the level each needs), the
/// odds it comes together this year, and the rewards a hobby can never give —
/// a portfolio piece (a professional credential), founder-cluster growth, and,
/// for marquee pieces, a fame trophy. The catalogue is filtered by life stage
/// and capped per year, exactly like hobbies.
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

    /// Projects offered this stage. Pieces the player has already built are
    /// dropped — a finished portfolio piece can't be earned twice.
    private var stageProjects: [Project] {
        Project.allCases.filter {
            $0.stages.contains(currentStage) && !player.lockedPortfolio.contains($0)
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
            Text("Spend your soft skills on a portfolio piece — \(currentStage.displayName), age \(player.age)")
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

        // Each required axis as "Nx🔍" (need level N) — mirrors how a hobby row
        // shows its weighted gains, but read as a requirement rather than a gain.
        let requirementPictos: String = project.requirements
            .compactMap { req -> String? in
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return req.weight > 1 ? "\(req.weight)x\(pic)" : pic
            }
            .joined(separator: " ")

        // Founder-cluster skills this project sharpens on success (axes no hobby
        // can build), rendered with their "+N" gain.
        let boostPictos: String = project.boosts
            .compactMap { (kp, delta) -> String? in
                let pk = kp as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[pk] else { return nil }
                return "\(pic)+\(delta)"
            }
            .joined(separator: " ")

        let requirementHint: String = project.requirements
            .map { req -> String in
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) (need \(req.weight))"
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
                    Text(project.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Requires: \(requirementPictos)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Text("🎲 ~\(odds)%")
                        Text("📁 Portfolio piece")
                        if !boostPictos.isEmpty {
                            Text(boostPictos)
                        }
                        if let fame = project.fameAward {
                            Text("🌟 \(fame)")
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
                isDisabled
                    ? "You can take up to \(GameConstants.maxProjectsPerYear) project(s) this year."
                    : ""
            )

            InfoHint(
                title: "\(project.pictogram) \(project.rawValue)",
                message: "Requires:\n\n\(requirementHint)\n\nUnlike a hobby, a project spends the soft skills you've built — the better you meet these, the likelier it ships. A finished project earns a portfolio piece"
                    + (boostPictos.isEmpty ? "" : " and sharpens founder skills no hobby can")
                    + (project.buildsFame
                        ? ", and can earn the “\(project.fameAward ?? "")” trophy — fame that helps land Show Business roles."
                        : ".")
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
