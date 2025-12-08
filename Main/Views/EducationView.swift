import SwiftUI

struct EducationView: View {
    @ObservedObject var player: Player

    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool

    private var availableEducations: [Education] {
        availableNextEducations(holds: player.degrees)
    }

    private var availableProfiles: [TertiaryProfile] {
        let profiles = availableEducations.compactMap { $0.profile }
        let unique = Set(profiles)
        return unique.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        Group {
            if #available(iOS 16, macOS 13, *) {
                NavigationStack {
                    content
                        .navigationTitle("Education")
                }
            } else {
                NavigationView {
                    content
                        .navigationTitle("Education")
                }
                #if os(iOS)
                    .navigationViewStyle(.stack)
                #endif
            }
        }
        .frame(minHeight: 500)
    }

    private var content: some View {
        List {
            Section {
                ForEach(availableProfiles, id: \.self) { profile in
                    NavigationLink {
                        DegreesSubmenuView(
                            player: player,
                            profile: profile,
                            degrees: degrees(for: profile),
                            yearsLeftToGraduation: $yearsLeftToGraduation,
                            showTertiarySheet: $showTertiarySheet
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(profile.rawValue.capitalized)
                                .font(.headline)
                            Text(profile.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                }
            } header: {
                Text("Pick your education direction")
            }

            Button("Close") {
                showTertiarySheet = false
            }
            .foregroundStyle(.secondary)

        }
    }

    private func degrees(for profile: TertiaryProfile) -> [Education] {
        availableEducations
            .filter { $0.profile == profile }
            .sorted { lhs, rhs in
                let order: [Level.Stage: Int] = [
                    .Vocational: 0, .Bachelor: 1, .Master: 2, .Doctorate: 3,
                ]
                return (order[lhs.level] ?? 99) < (order[rhs.level] ?? 99)
            }
    }
}

// MARK: - Submenu: Degrees for a profile

private struct DegreesSubmenuView: View {
    @ObservedObject var player: Player
    let profile: TertiaryProfile
    let degrees: [Education]
    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool

    private func requirementRow(
        label: String,
        emoji: String,
        level: Int,
        playerLevel: Int
    ) -> some View {
        let required = max(level, 0)
        let meets = playerLevel >= required

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
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .accessibilityHint(
            meets ? "\(label) requirement met" : "\(label) requirement not met"
        )
    }

    var body: some View {
        List {
            Section {
                ForEach(degrees) { education in
                    let r = education.requirements
                    let highestEQF = player.degrees.last?.eqf ?? 0
                    let meetsAll = education.meetsRequirements(player: player)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(education.degreeName)
                                    .font(.headline)
                                Text("Takes \(education.yearsToComplete) years")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                player.currentOccupation = nil
                                player.currentEducation = education
                                yearsLeftToGraduation =
                                    education.yearsToComplete
                                showTertiarySheet = false
                            } label: {
                                Text(
                                    meetsAll ? "Choose" : "Requirements not met"
                                )
                                .frame(maxWidth: 140)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!meetsAll)
                            .opacity(meetsAll ? 1.0 : 0.5)
                            .accessibilityHint(
                                meetsAll
                                    ? "All requirements met"
                                    : "Some requirements are not met"
                            )
                        }

                        // Requirements block (now includes new school-age skills)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What do you need?")
                                .font(.subheadline.bold())

                            // Education prerequisite (EQF)
                            requirementRow(
                                label: "Previous education",
                                emoji: "🎓",
                                level: r.minEQF,
                                playerLevel: highestEQF
                            )

                            // Brainy
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath:
                                        \.analyticalReasoningAndProblemSolving
                                ) ?? "Problem Solving",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath:
                                        \.analyticalReasoningAndProblemSolving
                                ) ?? "🧩",
                                level: r.analyticalReasoning,
                                playerLevel: player.softSkills
                                    .analyticalReasoningAndProblemSolving
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath:
                                        \.creativityAndInsightfulThinking
                                ) ?? "Creativity",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath:
                                        \.creativityAndInsightfulThinking
                                ) ?? "🎨",
                                level: r.creativeExpression,
                                playerLevel: player.softSkills
                                    .creativityAndInsightfulThinking
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.communicationAndNetworking
                                ) ?? "Communication",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.communicationAndNetworking
                                ) ?? "💬",
                                level: r.socialCommunication,
                                playerLevel: player.softSkills
                                    .communicationAndNetworking
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.leadershipAndInfluence
                                ) ?? "Leadership",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.leadershipAndInfluence
                                ) ?? "👥",
                                level: r.leadershipAndInfluence,
                                playerLevel: player.softSkills
                                    .leadershipAndInfluence
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.courageAndRiskTolerance
                                ) ?? "Courage",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.courageAndRiskTolerance
                                ) ?? "🎲",
                                level: r.riskTolerance,
                                playerLevel: player.softSkills
                                    .courageAndRiskTolerance
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.spacialNavigationAndOrientation
                                ) ?? "Navigation",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.spacialNavigationAndOrientation
                                ) ?? "🧭",
                                level: r.spatialThinking,
                                playerLevel: player.softSkills.spacialNavigationAndOrientation
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath:
                                        \.carefulnessAndAttentionToDetail
                                ) ?? "Carefulness",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath:
                                        \.carefulnessAndAttentionToDetail
                                ) ?? "🔎",
                                level: r.attentionToDetail,
                                playerLevel: player.softSkills
                                    .carefulnessAndAttentionToDetail
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.patienceAndPerseverance
                                ) ?? "Perseverance",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.patienceAndPerseverance
                                ) ?? "🛡️",
                                level: r.perseveranceAndGrit,
                                playerLevel: player.softSkills
                                    .patienceAndPerseverance
                            )

                            // Physical / hands-on
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.tinkeringAndFingerPrecision
                                ) ?? "Tinkering",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.tinkeringAndFingerPrecision
                                ) ?? "🔧",
                                level: r.tinkering,
                                playerLevel: player.softSkills
                                    .tinkeringAndFingerPrecision
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.physicalStrengthAndEndurance
                                ) ?? "Strength",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.physicalStrengthAndEndurance
                                ) ?? "💪",
                                level: r.physicalStrength,
                                playerLevel: player.softSkills.physicalStrengthAndEndurance
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.physicalStrengthAndEndurance
                                ) ?? "Endurance",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.physicalStrengthAndEndurance
                                ) ?? "🌦️",
                                level: r.endurance,
                                playerLevel: player.softSkills
                                    .physicalStrengthAndEndurance
                            )

                            // New school-age soft skills
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.stressResistanceAndEmotionalRegulation
                                ) ?? "Emotional Intelligence",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.stressResistanceAndEmotionalRegulation
                                ) ?? "🧘",
                                level: r.emotionalIntelligence,
                                playerLevel: player.softSkills.stressResistanceAndEmotionalRegulation
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.collaborationAndTeamwork
                                ) ?? "Collaboration",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.collaborationAndTeamwork
                                ) ?? "🤝",
                                level: r.collaborationAndTeamwork,
                                playerLevel: player.softSkills.collaborationAndTeamwork
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.timeManagementAndPlanning
                                ) ?? "Time Management",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.timeManagementAndPlanning
                                ) ?? "⏱️",
                                level: r.timeManagementAndPlanning,
                                playerLevel: player.softSkills.timeManagementAndPlanning
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.selfDisciplineAndStudyHabits
                                ) ?? "Study Habits",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.selfDisciplineAndStudyHabits
                                ) ?? "📚",
                                level: r.selfDisciplineAndStudyHabits,
                                playerLevel: player.softSkills.selfDisciplineAndStudyHabits
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.adaptabilityAndLearningAgility
                                ) ?? "Adaptability",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.adaptabilityAndLearningAgility
                                ) ?? "🔄",
                                level: r.adaptabilityAndLearningAgility,
                                playerLevel: player.softSkills.adaptabilityAndLearningAgility
                            )
                            requirementRow(
                                label: SoftSkills.label(
                                    forKeyPath: \.presentationAndStorytelling
                                ) ?? "Presentation",
                                emoji: SoftSkills.pictogram(
                                    forKeyPath: \.presentationAndStorytelling
                                ) ?? "🎤",
                                level: r.presentationAndStorytelling,
                                playerLevel: player.softSkills.presentationAndStorytelling
                            )
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text(profile.rawValue.capitalized)
            }
        }
        .navigationTitle(profile.rawValue.capitalized)
        .frame(minHeight: 400)
    }
}

#Preview {
    EducationView(
        player: Player(),
        yearsLeftToGraduation: .constant(nil),
        showTertiarySheet: .constant(true),
        showCareersSheet: .constant(false)
    )
}
