import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    @State private var softSkillsExpanded: Bool = false
    @State private var hardSkillsExpanded: Bool = false
    @State private var educationExpanded: Bool = false
    @State private var experienceExpanded: Bool = false

    private var projects: [Project] {
        Array(player.hardSkills.portfolioItems.union(appUIState.selectedPortfolio))
    }

    private var certifications: [Certification] {
        Array(appUIState.selectedCertifications.union(player.hardSkills.certifications))
    }

    private var licenses: [License] {
        Array(appUIState.selectedLicenses.union(player.hardSkills.licenses))
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
                // Hard skills (certs/licenses/portfolio) don't apply in simplified mode.
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

    // MARK: - Hard Skills

    private var hardSkillsSection: some View {
        DisclosureGroup(isExpanded: $hardSkillsExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if projects.isEmpty && certifications.isEmpty && licenses.isEmpty {
                    Text("No hard skills yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !projects.isEmpty {
                    hardSkillRow(title: "Projects") {
                        ForEach(projects) { item in
                            Text("\(item.id) \(item.pictogram)")
                        }
                    }
                }
                if !certifications.isEmpty {
                    hardSkillRow(title: "Certifications") {
                        ForEach(certifications) { cert in
                            Text("\(cert.friendlyName) \(cert.pictogram)")
                        }
                    }
                }
                if !licenses.isEmpty {
                    hardSkillRow(title: "Licenses") {
                        ForEach(licenses) { lic in
                            Text("\(lic.friendlyName) \(lic.pictogram)")
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
                summaryPictograms(
                    projects.map { $0.pictogram }
                        + certifications.map { $0.pictogram }
                        + licenses.map { $0.pictogram }
                )
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
