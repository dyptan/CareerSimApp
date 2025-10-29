import SwiftUI

struct DetailView: View {
    var detail: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    // Build a lookup from SoftSkills.skillNames to reuse pictograms consistently
    private var softSkillIconByLabel: [String: String] {
        Dictionary(uniqueKeysWithValues: SoftSkills.skillNames.map { ($0.label, $0.pictogram) })
    }

    // Convenience accessors for pictograms by field name
    private func icon(for label: String, fallback: String) -> String {
        softSkillIconByLabel[label] ?? fallback
    }

    // MARK: - Requirement checks

    private func playerEQF() -> Int {
        if let current = player.currentEducation?.1 {
            return current.eqf
        }
        if let last = player.degrees.last?.1 {
            return last.eqf
        }
        // Infer from age milestones in HeaderView logic if no Level recorded yet
        if player.age >= 18 { return Level.HighSchool.eqf }
        if player.age >= 14 { return Level.MiddleSchool.eqf }
        if player.age >= 10 { return Level.PrimarySchool.eqf }
        return Level.PrimarySchool.eqf
    }

    private func meets(skill required: Int, player has: Int) -> Bool {
        has >= required
    }

    private var educationMet: Bool {
        playerEQF() >= mapRequirementToEQF(detail.requirements.education)
    }

    // Map the requirement's compact scale (0..7) to EQF like in your Job.swift doc
    private func mapRequirementToEQF(_ requirement: Int) -> Int {
        switch requirement {
        case ..<1: return 1   // EQF 1
        case 1: return 1      // EQF 1
        case 2: return 3      // EQF 3
        case 3: return 4      // EQF 4 (High school)
        case 4: return 5      // EQF 5 (College/Vocational)
        case 5: return 6      // EQF 6 (Bachelor’s)
        case 6: return 7      // EQF 7 (Master’s)
        case 7: return 8      // EQF 8 (Doctorate)
        default: return 8
        }
    }

    private var unmetReasons: [String] {
        var missing: [String] = []

        if !educationMet {
            missing.append("Education \(detail.requirements.educationLabel())")
        }

        func check(_ label: String, required: Int, has: Int) {
            if !meets(skill: required, player: has) {
                missing.append("\(label) \(required)")
            }
        }

        let s = player.softSkills
        check("Analytical Reasoning", required: detail.requirements.analyticalReasoning, has: s.analyticalReasoning)
        check("Creative Expression", required: detail.requirements.creativeExpression, has: s.creativeExpression)
        check("Social Communication", required: detail.requirements.socialCommunication, has: s.socialCommunication)
        check("Team Leadership", required: detail.requirements.teamLeadership, has: s.teamLeadership)
        check("Influence & Networking", required: detail.requirements.influenceAndNetworking, has: s.influenceAndNetworking)
        check("Risk Tolerance", required: detail.requirements.riskTolerance, has: s.riskTolerance)
        check("Spatial Thinking", required: detail.requirements.spatialThinking, has: s.spatialThinking)
        check("Attention to Detail", required: detail.requirements.attentionToDetail, has: s.attentionToDetail)
        check("Cognitive Resilience", required: detail.requirements.resilienceCognitive, has: s.resilienceCognitive)

        check("Mechanical Operation", required: detail.requirements.mechanicalOperation, has: s.mechanicalOperation)
        check("Physical Ability", required: detail.requirements.physicalAbility, has: s.physicalAbility)
        check("Outdoor Orientation", required: detail.requirements.outdoorOrientation, has: 0) // Not tracked in SoftSkills
        check("Physical Resilience", required: detail.requirements.resiliencePhysical, has: s.resiliencePhysical)

        return missing
    }

    private var allRequirementsMet: Bool {
        unmetReasons.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(detail.icon)
                    .font(.system(size: 96))
                    .padding(.top, 16)

                Text(detail.id)
                    .font(.largeTitle.bold())

                Text(detail.category.rawValue)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    // Education removed from summary row; now in requirements
                    labelBox(
                        title: "Prestige",
                        content: pictos("😎", level: min(max(detail.prestige, 0), 5))
                    )
                    labelBox(
                        title: "Income",
                        content: VStack(spacing: 4) {
                            Text("\(detail.income)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(detail.reward())
                        }
                    )
                    labelBox(
                        title: "Reward",
                        content: Text(detail.reward())
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What is this job?")
                        .font(.title2.bold())
                    Text(detail.summary)
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
                                label: detail.requirements.educationLabel(),
                                emoji: "📚",
                                level: detail.requirements.education,
                                playerLevel: player.degrees.last?.1.eqf ?? 1
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
                            level: detail.requirements.analyticalReasoning,
                            playerLevel: player.softSkills.analyticalReasoning
                        )
                        requirementRow(
                            label: "Creative Expression",
                            emoji: icon(for: "Creative Expression", fallback: "🎨"),
                            level: detail.requirements.creativeExpression,
                            playerLevel: player.softSkills.creativeExpression
                        )
                        requirementRow(
                            label: "Social Communication",
                            emoji: icon(for: "Social Communication", fallback: "💬"),
                            level: detail.requirements.socialCommunication,
                            playerLevel: player.softSkills.socialCommunication
                        )
                        requirementRow(
                            label: "Team Leadership",
                            emoji: icon(for: "Team Leadership", fallback: "👥"),
                            level: detail.requirements.teamLeadership,
                            playerLevel: player.softSkills.teamLeadership
                        )
                        requirementRow(
                            label: "Influence & Networking",
                            emoji: icon(for: "Influence & Networking", fallback: "🤝"),
                            level: detail.requirements.influenceAndNetworking,
                            playerLevel: player.softSkills.influenceAndNetworking
                        )
                        requirementRow(
                            label: "Risk Tolerance",
                            emoji: icon(for: "Risk Tolerance", fallback: "🎲"),
                            level: detail.requirements.riskTolerance,
                            playerLevel: player.softSkills.riskTolerance
                        )
                        requirementRow(
                            label: "Spatial Thinking",
                            emoji: icon(for: "Spatial Thinking", fallback: "🧭"),
                            level: detail.requirements.spatialThinking,
                            playerLevel: player.softSkills.spatialThinking
                        )
                        requirementRow(
                            label: "Attention to Detail",
                            emoji: icon(for: "Attention to Detail", fallback: "🔎"),
                            level: detail.requirements.attentionToDetail,
                            playerLevel: player.softSkills.attentionToDetail
                        )
                        requirementRow(
                            label: "Cognitive Resilience",
                            emoji: icon(for: "Cognitive Resilience", fallback: "🧩"),
                            level: detail.requirements.resilienceCognitive,
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
                            level: detail.requirements.mechanicalOperation,
                            playerLevel: player.softSkills.mechanicalOperation
                        )
                        requirementRow(
                            label: "Physical Ability",
                            emoji: icon(for: "Physical Ability", fallback: "💪"),
                            level: detail.requirements.physicalAbility,
                            playerLevel: player.softSkills.physicalAbility
                        )
                        requirementRow(
                            label: "Outdoor Orientation",
                            emoji: "🌲",
                            level: detail.requirements.outdoorOrientation,
                            playerLevel: 0
                        )
                        requirementRow(
                            label: "Physical Resilience",
                            emoji: icon(for: "Physical Resilience", fallback: "🛡️"),
                            level: detail.requirements.resiliencePhysical,
                            playerLevel: player.softSkills.resiliencePhysical
                        )
                    }
                    .padding(.vertical, 6)
                }
                .padding(.horizontal)

                Button {
                    player.currentOccupation = detail
                    showCareersSheet.toggle()
                } label: {
                    Text(allRequirementsMet ? "Choose this job" : "Requirements not met")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!allRequirementsMet)
                .opacity(allRequirementsMet ? 1.0 : 0.5)
                .accessibilityHint(allRequirementsMet ? "All requirements met" : "Missing: \(unmetReasons.joined(separator: ", "))")
                .padding()
            }
            .padding(.bottom, 24)
        }
        .accessibilityIdentifier("CareerDetailRoot")
        .navigationTitle("")
    }

    // MARK: - Pictogram helpers

    private func pictos(_ emoji: String, level: Int) -> some View {
        let clamped = min(max(level, 0), 5)
        return Text(String(repeating: emoji, count: clamped))
            .font(.body)
    }

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
        if let first = detailsAll.first {
            DetailView(detail: first, player: Player(), showCareersSheet: .constant(true))
        } else {
            Text("No careers loaded")
        }
    }
}
