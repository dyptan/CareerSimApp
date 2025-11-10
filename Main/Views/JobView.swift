import SwiftUI

struct JobView: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var softSkillIconByLabel: [String: String] {
        Dictionary(uniqueKeysWithValues: SoftSkills.skillNames.map { ($0.label, $0.pictogram) })
    }

    private func icon(for label: String, fallback: String) -> String {
        softSkillIconByLabel[label] ?? fallback
    }

    // MARK: - Requirement checks

    private var allRequirementsMet: Bool {
        let p = player.softSkills
        let j = job.requirements

        // Leadership/networking merge: take the tougher of the two requirements
        let leadershipRequired = max(j.teamLeadership, j.influenceAndNetworking)

        let unmet =
            (player.degrees.last?.1.eqf ?? 0) < j.education
            || p.problemSolving < j.analyticalReasoning
            || p.creativity < j.creativeExpression
            || p.communication < j.socialCommunication
            || p.leadershipAndFriends < leadershipRequired
            || p.riskTaking < j.riskTolerance
            || p.navigation < j.spatialThinking
            || p.carefulness < j.attentionToDetail
            || p.focusAndGrit < j.resilienceCognitive
            || p.tinkering < j.mechanicalOperation
            || p.strength < j.physicalAbility
            || p.stamina < j.resiliencePhysical
            || p.weatherEndurance < j.outdoorOrientation

        return !unmet
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(job.icon)
                    .font(.system(size: 96))
                    .padding(.top, 16)

                Text(job.id)
                    .font(.largeTitle.bold())

                Text(job.category.rawValue)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    labelBox(
                        title: "Prestige",
                        content: Text(emojiForLevel(job.prestige))
                    )
                    labelBox(
                        title: "Income",
                        content: HStack(spacing: 4) {
                            Text("\(job.income)K")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(job.reward())
                        }
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What is this job?")
                        .font(.title2.bold())
                    Text(job.summary)
                        .font(.body)
                }
                .padding()

                // Requirements
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you need?")
                        .font(.title2.bold())

                    // Education
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Education")
                            .font(.headline)
                        HStack {
                            requirementRow(
                                label: job.requirements.educationLabel(),
                                emoji: "📚",
                                level: job.requirements.education,
                                playerLevel: player.degrees.last?.1.eqf ?? 0
                            )
                        }
                    }
                    .padding(.vertical, 6)

                    // Brainy (cognitive)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brainy skills")
                            .font(.headline)
                        requirementRow(
                            label: "Problem Solving",
                            emoji: icon(for: "Problem Solving", fallback: "🧩"),
                            level: job.requirements.analyticalReasoning,
                            playerLevel: player.softSkills.problemSolving
                        )
                        requirementRow(
                            label: "Creativity",
                            emoji: icon(for: "Creativity", fallback: "🎨"),
                            level: job.requirements.creativeExpression,
                            playerLevel: player.softSkills.creativity
                        )
                        requirementRow(
                            label: "Communication",
                            emoji: icon(for: "Communication", fallback: "💬"),
                            level: job.requirements.socialCommunication,
                            playerLevel: player.softSkills.communication
                        )
                        requirementRow(
                            label: "Leadership & Friends",
                            emoji: icon(for: "Leadership & Friends", fallback: "👥"),
                            level: max(job.requirements.teamLeadership, job.requirements.influenceAndNetworking),
                            playerLevel: player.softSkills.leadershipAndFriends
                        )
                        requirementRow(
                            label: "Risk Taking",
                            emoji: icon(for: "Risk Taking", fallback: "🎲"),
                            level: job.requirements.riskTolerance,
                            playerLevel: player.softSkills.riskTaking
                        )
                        requirementRow(
                            label: "Navigation",
                            emoji: icon(for: "Navigation", fallback: "🧭"),
                            level: job.requirements.spatialThinking,
                            playerLevel: player.softSkills.navigation
                        )
                        requirementRow(
                            label: "Carefulness",
                            emoji: icon(for: "Carefulness", fallback: "🔎"),
                            level: job.requirements.attentionToDetail,
                            playerLevel: player.softSkills.carefulness
                        )
                        requirementRow(
                            label: "Focus & Grit",
                            emoji: icon(for: "Focus & Grit", fallback: "🧠"),
                            level: job.requirements.resilienceCognitive,
                            playerLevel: player.softSkills.focusAndGrit
                        )
                    }
                    .padding(.vertical, 6)

                    // Body & hands-on (physical)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body & hands-on")
                            .font(.headline)
                        requirementRow(
                            label: "Tinkering",
                            emoji: icon(for: "Tinkering", fallback: "🛠️"),
                            level: job.requirements.mechanicalOperation,
                            playerLevel: player.softSkills.tinkering
                        )
                        requirementRow(
                            label: "Strength",
                            emoji: icon(for: "Strength", fallback: "💪"),
                            level: job.requirements.physicalAbility,
                            playerLevel: player.softSkills.strength
                        )
                        requirementRow(
                            label: "Weather Endurance",
                            emoji: "🌦️💪",
                            level: job.requirements.outdoorOrientation,
                            playerLevel: player.softSkills.weatherEndurance
                        )
                        requirementRow(
                            label: "Stamina",
                            emoji: icon(for: "Stamina", fallback: "🛡️"),
                            level: job.requirements.resiliencePhysical,
                            playerLevel: player.softSkills.stamina
                        )
                    }
                    .padding(.vertical, 6)
                }
                .padding(.horizontal)

                Button {
                    player.currentOccupation = job
                    showCareersSheet.toggle()
                } label: {
                    Text(allRequirementsMet ? "Choose this job" : "Requirements not met")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!allRequirementsMet)
                .opacity(allRequirementsMet ? 1.0 : 0.5)
                .accessibilityHint(allRequirementsMet ? "All requirements met" : "Some requirements are not met")
                .padding()
            }
            .padding(.bottom, 24)
        }
        .accessibilityIdentifier("CareerDetailRoot")
        .navigationTitle("")
    }

    // MARK: - Level-to-emoji mapping

    // You can tweak thresholds freely.
    private func emojiForLevel(_ value: Int) -> String {
        switch value {
        case ..<1: return "😞"     // none
        case 1...2: return "☹️"    // weak
        case 3...4: return "🙂"    // okay
        case 5...6: return "😎"    // high
        default: return "⭐️"       // very high
        }
    }

    // MARK: - Pictogram helpers (now qualitative)

    private func requirementRow(label: String, emoji: String, level: Int, playerLevel: Int) -> some View {
        let required = max(level, 0)
        let meets = playerLevel >= required
        let requiredEmoji = emojiForLevel(required)
        let playerEmoji = emojiForLevel(playerLevel)

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 6) {
                // Show required vs player with small legend via accessibility
                Text(requiredEmoji)
                    .opacity(0.8)
                    .help("Required level")
                Text(playerEmoji)
                    .opacity(meets ? 1.0 : 0.6)
                    .help("Your level")
            }
            .font(.body)
            .accessibilityLabel("\(label). Required \(requiredEmoji). You \(playerEmoji).")
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .accessibilityHint(meets ? "\(label) requirement met" : "\(label) requirement not met")
    }

    private func stars(level: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= level ? "star.fill" : "star")
                    .foregroundStyle(i <= level ? .yellow : .gray)
            }
        }
    }

    private func labelBox<T: View>(title: String, content: T) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
                .font(.body)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        if let first = jobs.first {
            JobView(job: first, player: Player(), showCareersSheet: .constant(true))
        } else {
            Text("No careers loaded")
        }
    }
}
