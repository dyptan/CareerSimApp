import SwiftUI

extension SoftSkills {
    static func pictogram(forLabel label: String) -> String? {
        skillNames.first(where: { $0.label == label })?.pictogram
    }
    static func label(forKeyPath keyPath: WritableKeyPath<SoftSkills, Int>) -> String? {
        skillNames.first(where: { $0.keyPath == keyPath })?.label
    }
    static func pictogram(forKeyPath keyPath: WritableKeyPath<SoftSkills, Int>) -> String? {
        skillNames.first(where: { $0.keyPath == keyPath })?.pictogram
    }
}

struct JobView: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    // MARK: - Requirement checks

    private var allRequirementsMet: Bool {
        let p = player.softSkills
        let j = job.requirements

        // Leadership/networking merge: take the tougher of the two requirements
        let leadershipRequired = max(j.teamLeadership, j.influenceAndNetworking)

        let unmet =
            (player.degrees.last?.eqf ?? 0) < j.education
            || p.analyticalReasoningAndProblemSolving < j.analyticalReasoning
            || p.creativityAndInsightfulThinking < j.creativeExpression
            || p.communicationAndNetworking < j.socialCommunication
            || p.leadershipAndInfluence < leadershipRequired
            || p.courageAndRiskTolerance < j.riskTolerance
            || p.spacialNavigation < j.spatialThinking
            || p.carefulnessAndAttentionToDetail < j.attentionToDetail
            || p.perseveranceAndGrit < j.resilienceCognitive
            || p.tinkeringAndFingerPrecision < j.mechanicalOperation
            || p.physicalStrength < j.physicalAbility
            || p.resilienceAndEndurance < j.resiliencePhysical
            || p.resilienceAndEndurance < j.outdoorOrientation

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
                        content: Text(String(repeating: "😎", count: job.prestige))
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
                                emoji: "🎓",
                                level: job.requirements.education,
                                playerLevel: player.degrees.last?.eqf ?? 0
                            )
                        }
                    }
                    .padding(.vertical, 6)

                    // Brainy (cognitive)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brainy skills")
                            .font(.headline)
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.analyticalReasoningAndProblemSolving) ?? "Problem Solving",
                            emoji: SoftSkills.pictogram(forKeyPath: \.analyticalReasoningAndProblemSolving) ?? "🧩",
                            level: job.requirements.analyticalReasoning,
                            playerLevel: player.softSkills.analyticalReasoningAndProblemSolving
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.creativityAndInsightfulThinking) ?? "Creativity",
                            emoji: SoftSkills.pictogram(forKeyPath: \.creativityAndInsightfulThinking) ?? "🎨",
                            level: job.requirements.creativeExpression,
                            playerLevel: player.softSkills.creativityAndInsightfulThinking
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.communicationAndNetworking) ?? "Communication",
                            emoji: SoftSkills.pictogram(forKeyPath: \.communicationAndNetworking) ?? "💬",
                            level: job.requirements.socialCommunication,
                            playerLevel: player.softSkills.communicationAndNetworking
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.leadershipAndInfluence) ?? "Leadership",
                            emoji: SoftSkills.pictogram(forKeyPath: \.leadershipAndInfluence) ?? "👥",
                            level: max(job.requirements.teamLeadership, job.requirements.influenceAndNetworking),
                            playerLevel: player.softSkills.leadershipAndInfluence
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.courageAndRiskTolerance) ?? "Courage",
                            emoji: SoftSkills.pictogram(forKeyPath: \.courageAndRiskTolerance) ?? "🎲",
                            level: job.requirements.riskTolerance,
                            playerLevel: player.softSkills.courageAndRiskTolerance
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.spacialNavigation) ?? "Navigation",
                            emoji: SoftSkills.pictogram(forKeyPath: \.spacialNavigation) ?? "🧭",
                            level: job.requirements.spatialThinking,
                            playerLevel: player.softSkills.spacialNavigation
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.carefulnessAndAttentionToDetail) ?? "Carefulness",
                            emoji: SoftSkills.pictogram(forKeyPath: \.carefulnessAndAttentionToDetail) ?? "🔎",
                            level: job.requirements.attentionToDetail,
                            playerLevel: player.softSkills.carefulnessAndAttentionToDetail
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.perseveranceAndGrit) ?? "Perseverance",
                            emoji: SoftSkills.pictogram(forKeyPath: \.perseveranceAndGrit) ?? "🛡️",
                            level: job.requirements.resilienceCognitive,
                            playerLevel: player.softSkills.perseveranceAndGrit
                        )
                    }
                    .padding(.vertical, 6)

                    // Body & hands-on (physical)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body & hands-on")
                            .font(.headline)
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.tinkeringAndFingerPrecision) ?? "Tinkering",
                            emoji: SoftSkills.pictogram(forKeyPath: \.tinkeringAndFingerPrecision) ?? "🔧",
                            level: job.requirements.mechanicalOperation,
                            playerLevel: player.softSkills.tinkeringAndFingerPrecision
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.physicalStrength) ?? "Strength",
                            emoji: SoftSkills.pictogram(forKeyPath: \.physicalStrength) ?? "💪",
                            level: job.requirements.physicalAbility,
                            playerLevel: player.softSkills.physicalStrength
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.coordinationAndBalance) ?? "Coordination",
                            emoji: SoftSkills.pictogram(forKeyPath: \.coordinationAndBalance) ?? "🤸",
                            level: 0,
                            playerLevel: player.softSkills.coordinationAndBalance
                        )
                        requirementRow(
                            label: SoftSkills.label(forKeyPath: \.resilienceAndEndurance) ?? "Endurance",
                            emoji: SoftSkills.pictogram(forKeyPath: \.resilienceAndEndurance) ?? "🌦️",
                            level: max(job.requirements.resiliencePhysical, job.requirements.outdoorOrientation),
                            playerLevel: player.softSkills.resilienceAndEndurance
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

    // MARK: - Pictogram helpers (now qualitative)

    private func requirementRow(label: String, emoji: String, level: Int, playerLevel: Int) -> some View {
        let required = max(level, 0)
        let meets = playerLevel >= required

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<required, id: \.self) { idx in
                    Text(emoji)
                        .opacity(idx < playerLevel ? 1.0 : 0.35)
                }}
            .font(.body)
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

// Standalone preview with a sample job
#Preview {
    let exampleJob = Job(
        id: "SampleJob",
        category: .agriculture,
        income: 1000,
        prestige: 3,
        summary: "Test job for preview.",
        icon: "🧑‍🌾",
        requirements: Job.Requirements(
            education: 1,
            cognitive: Job.Requirements.Cognitive(
                analyticalReasoning: 1,
                creativeExpression: 1,
                socialCommunication: 1,
                teamLeadership: 1,
                influenceAndNetworking: 1,
                riskTolerance: 1,
                spatialThinking: 1,
                attentionToDetail: 1,
                resilienceCognitive: 1
            ),
            physical: Job.Requirements.Physical(
                mechanicalOperation: 1,
                physicalAbility: 1,
                outdoorOrientation: 1,
                resiliencePhysical: 1,
                endurance: 1
            )
        ),
        version: 1
    )
    if #available(macOS 13.0, *) {
        return NavigationStack {
            JobView(job: exampleJob, player: Player(), showCareersSheet: .constant(true))
        }
    } else {
        return NavigationView {
            JobView(job: exampleJob, player: Player(), showCareersSheet: .constant(true))
        }
    }
}

