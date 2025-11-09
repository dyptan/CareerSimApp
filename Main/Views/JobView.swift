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

        let unmet =
            player.degrees.last?.1.eqf ?? 0 < j.education
            || p.analyticalReasoning < j.analyticalReasoning
            || p.creativeExpression < j.creativeExpression
            || p.socialCommunication < j.socialCommunication
            || p.teamLeadership < j.teamLeadership
            || p.influenceAndNetworking < j.influenceAndNetworking
            || p.riskTolerance < j.riskTolerance
            || p.spatialThinking < j.spatialThinking
            || p.attentionToDetail < j.attentionToDetail
            || p.resilienceCognitive < j.resilienceCognitive
            || p.mechanicalOperation < j.mechanicalOperation
            || p.physicalAbility < j.physicalAbility
            || p.resiliencePhysical < j.resiliencePhysical
            || p.outdoorOrientation < j.outdoorOrientation

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
                    // Education removed from summary row; now in requirements
                    labelBox(
                        title: "Prestige",
                        content: Text(String(repeating:"😎", count: job.prestige))
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
                            label: "Analytical Reasoning",
                            emoji: icon(for: "Analytical Reasoning", fallback: "🧠"),
                            level: job.requirements.analyticalReasoning,
                            playerLevel: player.softSkills.analyticalReasoning
                        )
                        requirementRow(
                            label: "Creative Expression",
                            emoji: icon(for: "Creative Expression", fallback: "🎨"),
                            level: job.requirements.creativeExpression,
                            playerLevel: player.softSkills.creativeExpression
                        )
                        requirementRow(
                            label: "Social Communication",
                            emoji: icon(for: "Social Communication", fallback: "💬"),
                            level: job.requirements.socialCommunication,
                            playerLevel: player.softSkills.socialCommunication
                        )
                        requirementRow(
                            label: "Team Leadership",
                            emoji: icon(for: "Team Leadership", fallback: "👥"),
                            level: job.requirements.teamLeadership,
                            playerLevel: player.softSkills.teamLeadership
                        )
                        requirementRow(
                            label: "Influence & Networking",
                            emoji: icon(for: "Influence & Networking", fallback: "🤝"),
                            level: job.requirements.influenceAndNetworking,
                            playerLevel: player.softSkills.influenceAndNetworking
                        )
                        requirementRow(
                            label: "Risk Tolerance",
                            emoji: icon(for: "Risk Tolerance", fallback: "🎲"),
                            level: job.requirements.riskTolerance,
                            playerLevel: player.softSkills.riskTolerance
                        )
                        requirementRow(
                            label: "Spatial Thinking",
                            emoji: icon(for: "Spatial Thinking", fallback: "🧭"),
                            level: job.requirements.spatialThinking,
                            playerLevel: player.softSkills.spatialThinking
                        )
                        requirementRow(
                            label: "Attention to Detail",
                            emoji: icon(for: "Attention to Detail", fallback: "🔎"),
                            level: job.requirements.attentionToDetail,
                            playerLevel: player.softSkills.attentionToDetail
                        )
                        requirementRow(
                            label: "Cognitive Resilience",
                            emoji: icon(for: "Cognitive Resilience", fallback: "🧩"),
                            level: job.requirements.resilienceCognitive,
                            playerLevel: player.softSkills.resilienceCognitive
                        )
                    }
                    .padding(.vertical, 6)

                    // Body & hands-on (physical)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body & hands-on")
                            .font(.headline)
                        requirementRow(
                            label: "Mechanical Operation",
                            emoji: icon(for: "Mechanical Operation", fallback: "🛠️"),
                            level: job.requirements.mechanicalOperation,
                            playerLevel: player.softSkills.mechanicalOperation
                        )
                        requirementRow(
                            label: "Physical Ability",
                            emoji: icon(for: "Physical Ability", fallback: "💪"),
                            level: job.requirements.physicalAbility,
                            playerLevel: player.softSkills.physicalAbility
                        )
                        requirementRow(
                            label: "Outdoor Orientation",
                            emoji: "🌲",
                            level: job.requirements.outdoorOrientation,
                            playerLevel: player.softSkills.outdoorOrientation
                        )
                        requirementRow(
                            label: "Physical Resilience",
                            emoji: icon(for: "Physical Resilience", fallback: "🛡️"),
                            level: job.requirements.resiliencePhysical,
                            playerLevel: player.softSkills.resiliencePhysical
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

    // MARK: - Pictogram helpers

    private func requirementRow(label: String, emoji: String, level: Int, playerLevel: Int) -> some View {
        let required = max(level, 0)
        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<required, id: \.self) { idx in
                    Text(emoji)
                        .opacity(idx < playerLevel ? 1.0 : 0.35)
                }
            }
            .font(.body)
            .accessibilityLabel("\(label) required \(required), you have \(playerLevel)")
        }
        .font(.body)
        .accessibilityHint(playerLevel >= required ? "\(label) requirement met" : "\(label) requirement not met")
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
