import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    @State private var softSkillsExpanded: Bool = false
    @State private var fameExpanded: Bool = false
    @State private var hardSkillsExpanded: Bool = false
    @State private var educationExpanded: Bool = false
    @State private var experienceExpanded: Bool = false

    private var trainings: [Training] {
        Array(appUIState.selectedTrainings.union(player.hardSkills.trainings))
    }

    private var nonZeroSoftSkills: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String, description: String)] {
        SoftSkills.skillNames.filter { player.softSkills[keyPath: $0.keyPath] > 0 }
    }

    private var experienceEntries: [(role: String, years: Int)] {
        player.experienceByRole
            .filter { $0.value > 0 }
            .map { ($0.key, $0.value) }
            .sorted { $0.years > $1.years }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                softSkillsSection
                Divider()
                fameSection
                Divider()
                // Hard skills (trainings: certs/licenses) don't apply in simplified mode.
                if !player.isSimplified {
                    hardSkillsSection
                    Divider()
                }
                educationSection
                Divider()
                experienceSection
            }
        }
    }

    // MARK: - Soft Skills

    private var softSkillsSection: some View {
        DisclosureGroup(isExpanded: $softSkillsExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(
                    Array(SoftSkills.skillNames.enumerated()),
                    id: \.offset
                ) { (_, skill) in
                    HStack {
                        Text(skill.label)
                        InfoHint(title: "\(skill.pictogram) \(skill.label)", message: skill.description)
                        Spacer()
                        let count = player.softSkills[keyPath: skill.keyPath]
                        Text(count == 0 ? " " : count <= 5 ? String(repeating: skill.pictogram, count: count) : "\(count)x\(skill.pictogram)")
                            .monospacedDigit()
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Soft Skills").font(.headline)
                Spacer()
                summaryPictograms(nonZeroSoftSkills.map { $0.pictogram })
            }
        }
    }

    // MARK: - Fame

    /// The third pillar of career capital: *what you're known for*. Fame is
    /// industry-scoped — only same-industry reputation lifts hiring and promotion
    /// odds there — so the section shows the fame score per field. The individual
    /// accolades are surfaced once in the status log as they're earned.
    private var fameSection: some View {
        DisclosureGroup(isExpanded: $fameExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if player.fameAwards.isEmpty {
                    Text("No fame yet — win a competition or ship a standout project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.fameByIndustry, id: \.industry) { group in
                        HStack {
                            Text(fameIndustryLabel(group.industry))
                            Spacer()
                            Text("🌟 \(String(format: "%.1f", group.score))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Fame").font(.headline)
                Spacer()
                // Per-industry split, visible even when the section is collapsed.
                if player.fameAwards.isEmpty {
                    Text("🌟 0.0")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(fameIndustrySummary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Icon + name for a fame group's industry (`nil` = general renown).
    private func fameIndustryLabel(_ industry: JobCategory?) -> String {
        industry.map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" } ?? "🌐 General"
    }

    /// Compact per-industry fame chips for the collapsed section label, e.g.
    /// "🎬 3.0  💻 1.0" — highest-scoring field first.
    private var fameIndustrySummary: String {
        player.fameByIndustry
            .map { group in
                let icon = group.industry.map { JobCategory.icon(for: $0) } ?? "🌐"
                return "\(icon) \(String(format: "%.1f", group.score))"
            }
            .joined(separator: "  ")
    }

    // MARK: - Hard Skills

    private var hardSkillsSection: some View {
        DisclosureGroup(isExpanded: $hardSkillsExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if trainings.isEmpty {
                    Text("No hard skills yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    hardSkillRow(title: "Trainings") {
                        ForEach(trainings) { training in
                            Text("\(training.friendlyName) \(training.pictogram)")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Hard Skills").font(.headline)
                Spacer()
                summaryPictograms(trainings.map { $0.pictogram })
            }
        }
    }

    @ViewBuilder
    private func hardSkillRow<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
        }
    }

    // MARK: - Education

    private var educationSection: some View {
        DisclosureGroup(isExpanded: $educationExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if player.degrees.isEmpty {
                    Text("No degrees yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.degrees, id: \.degreeName) { degree in
                        HStack {
                            Text(degree.pictogram)
                            Text(degree.degreeName)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Education").font(.headline)
                Spacer()
                summaryPictograms(player.degrees.map { $0.pictogram })
            }
        }
    }

    // MARK: - Work Experience

    private var experienceSection: some View {
        DisclosureGroup(isExpanded: $experienceExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if experienceEntries.isEmpty {
                    Text("No work experience yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(experienceEntries, id: \.role) { entry in
                        HStack {
                            Text("💼")
                            Text(entry.role)
                            Spacer()
                            Text("\(entry.years) yr\(entry.years == 1 ? "" : "s")")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Work Experience").font(.headline)
                Spacer()
                summaryPictograms(experienceEntries.map { _ in "💼" })
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func summaryPictograms(_ pictograms: [String]) -> some View {
        let visible = pictograms.prefix(6)
        let overflow = pictograms.count - visible.count
        HStack(spacing: 2) {
            ForEach(Array(visible.enumerated()), id: \.offset) { _, p in
                Text(p)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let player = Player()
    let appUIState = AppUIState()
    return SkillsView(
        player: player,
        appUIState: appUIState
    )
    .padding()
}
