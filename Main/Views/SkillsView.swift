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

    // MARK: - Personality

    private var softSkillsSection: some View {
        DisclosureGroup(isExpanded: $softSkillsExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(
                    Array(SoftSkills.skillNames.enumerated()),
                    id: \.offset
                ) { (index, skill) in
                    HStack {
                        Text(skill.label)
                        InfoHint(title: "\(skill.pictogram) \(skill.label)", message: skill.description)
                        Spacer()
                        skillStars(level: player.softSkills[keyPath: skill.keyPath])
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 4)
                    // Zebra striping, so the eye can follow a row from the
                    // skill's name to its stars across the panel's width.
                    .background(
                        index.isMultiple(of: 2)
                            ? Color.clear
                            : Color.secondary.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Personality").font(.headline)
        }
    }

    // MARK: - Fame

    /// The third pillar of career capital: *what you're known for*. Fame is
    /// bucket-scoped — only same-bucket reputation lifts hiring and promotion
    /// odds there — so the section shows the fame score per `FameCategory`. The
    /// individual accolades are surfaced once in the status log as they're earned.
    private var fameSection: some View {
        DisclosureGroup(isExpanded: $fameExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if player.fameAwards.isEmpty {
                    Text("No fame yet — win a competition or ship a standout project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.fameByCategory, id: \.category) { group in
                        HStack {
                            Text(fameCategoryLabel(group.category))
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
            Text("Fame").font(.headline)
        }
    }

    /// Icon + name for a fame group's bucket (`nil` = general renown).
    private func fameCategoryLabel(_ category: FameCategory?) -> String {
        category.map { "\($0.icon) \($0.rawValue)" } ?? "🌐 General"
    }

    // MARK: - Skills

    private var hardSkillsSection: some View {
        DisclosureGroup(isExpanded: $hardSkillsExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if trainings.isEmpty {
                    Text("No skills yet.")
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
            Text("Skills").font(.headline)
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
                    ForEach(player.degrees, id: \.id) { degree in
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
            Text("Education").font(.headline)
        }
    }

    // MARK: - Experience

    private var experienceSection: some View {
        DisclosureGroup(isExpanded: $experienceExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if experienceEntries.isEmpty {
                    Text("No experience yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(experienceEntries, id: \.role) { entry in
                        HStack {
                            Text(roleIcon(entry.role))
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
            Text("Experience").font(.headline)
        }
    }

    /// The pictogram for an experience role — its own industry icon, falling back
    /// to the generic briefcase for a title the catalogue doesn't recognise.
    private func roleIcon(_ role: String) -> String {
        JobCatalog.iconByBaseTitle[role] ?? "💼"
    }

    // MARK: - Helpers

    /// A soft-skill level as a row of stars — one per point, up to the 10 cap.
    private func skillStars(level: Int) -> some View {
        Text(String(repeating: "★", count: max(0, min(level, 10))))
            .foregroundColor(.yellow)
            .font(.caption)
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
