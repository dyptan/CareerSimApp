import SwiftUI

struct JobDetail: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    private var requiredSoft: Job.Requirements.SoftSkillsBlock {
        job.requirements.softSkills
    }
    private var requiredHard: Job.Requirements.HardSkillsBlock {
        job.requirements.hardSkills
    }

    private func certFrom(raw: String) -> Certification? {
        Certification(rawValue: raw)
    }
    private func licenseFrom(raw: String) -> License? {

        switch raw {
        case "B", "Driver's License": return .drivers
        case "CE", "CDL": return .cdl
        case "RN", "Nurse", "Nurse License": return .nurse
        case "EL", "Electrician License": return .electrician
        case "PL", "Plumber License": return .plumber
        default:
            return License(rawValue: raw)
        }
    }
    
    private func softwareFrom(raw: String) -> Software? {
        switch raw {
        case "Office": return .officeSuite
        case "Programming": return .programming
        case "Photo/Video Editing": return .mediaEditing
        case "Game Engine": return .gameEngine
        default:
            return Software(rawValue: raw)
        }
    }
    
    private func portfolioFrom(raw: String) -> Project? {
        Project(rawValue: raw)
    }

    // MARK: - Requirement checks

    private var educationMet: Bool {
        let playerEQF = player.degrees.last?.eqf ?? 0
        guard playerEQF >= job.requirements.education.minEQF else {
            return false
        }

        if let accepted = job.requirements.education.acceptedProfiles,
            !accepted.isEmpty
        {
            let playerProfiles = player.degrees.compactMap { $0.profile }
            if playerProfiles.isEmpty { return false }
            return playerProfiles.contains(where: { accepted.contains($0) })
        }

        return true
    }

    // Soft skills no longer gate jobs; keep computed but unused (for display)
    private var softSkillsHelpfulScore: Int {
        let p = player.softSkills
        let r = requiredSoft
        var score = 0
        if p.analyticalReasoningAndProblemSolving >= r.analyticalReasoningAndProblemSolving { score += 1 }
        if p.creativityAndInsightfulThinking >= r.creativityAndInsightfulThinking { score += 1 }
        if p.communicationAndNetworking >= r.communicationAndNetworking { score += 1 }
        if p.leadershipAndInfluence >= r.leadershipAndInfluence { score += 1 }
        if p.courageAndRiskTolerance >= r.courageAndRiskTolerance { score += 1 }
        if p.spacialNavigationAndOrientation >= r.spacialNavigation { score += 1 }
        if p.carefulnessAndAttentionToDetail >= r.carefulnessAndAttentionToDetail { score += 1 }
        if p.patienceAndPerseverance >= r.perseveranceAndGrit { score += 1 }
        if p.tinkeringAndFingerPrecision >= r.tinkeringAndFingerPrecision { score += 1 }
        if p.physicalStrengthAndEndurance >= r.physicalStrength { score += 1 }
        if p.coordinationAndBalance >= r.coordinationAndBalance { score += 1 }
        if p.physicalStrengthAndEndurance >= r.resilienceAndEndurance { score += 1 }
        return score
    }

    private var hardSkillsMet: Bool {
        let certsOK = requiredHard.certifications.allSatisfy { code in
            guard let enumVal = certFrom(raw: code) else { return false }
            return player.hardSkills.certifications.contains(enumVal)
        }
        let licensesOK = requiredHard.licenses.allSatisfy { code in
            guard let enumVal = licenseFrom(raw: code) else { return false }
            return player.hardSkills.licenses.contains(enumVal)
        }
        let softwareOK = requiredHard.software.allSatisfy { code in
            guard let enumVal = softwareFrom(raw: code) else { return false }
            return player.hardSkills.software.contains(enumVal)
        }
        let portfolioOK = requiredHard.portfolio.allSatisfy { code in
            guard let enumVal = portfolioFrom(raw: code) else { return false }
            return player.hardSkills.portfolioItems.contains(enumVal)
        }
        return certsOK && licensesOK && softwareOK && portfolioOK
    }

    private var allRequirementsMet: Bool {
        // Emphasize degree + hard skills; soft skills are helpful only
        educationMet && hardSkillsMet
    }

    // MARK: - UI helpers

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
        .padding(.horizontal)
    }

    private func softLabel(for keyPath: WritableKeyPath<SoftSkills, Int>) -> String {
        switch keyPath {
        case \.analyticalReasoningAndProblemSolving: return "Analytical reasoning"
        case \.creativityAndInsightfulThinking: return "Creativity"
        case \.communicationAndNetworking: return "Communication"
        case \.leadershipAndInfluence: return "Leadership"
        case \.courageAndRiskTolerance: return "Courage"
        case \.spacialNavigationAndOrientation: return "Spatial navigation"
        case \.carefulnessAndAttentionToDetail: return "Attention to detail"
        case \.patienceAndPerseverance: return "Perseverance"
        case \.tinkeringAndFingerPrecision: return "Finger precision"
        case \.physicalStrengthAndEndurance: return "Strength & endurance"
        case \.coordinationAndBalance: return "Coordination & balance"
        default: return ""
        }
    }
    
    private func softPictogram(for keyPath: WritableKeyPath<SoftSkills, Int>) -> String {
        switch keyPath {
        case \.analyticalReasoningAndProblemSolving: return "🧠"
        case \.creativityAndInsightfulThinking: return "🎨"
        case \.communicationAndNetworking: return "🗣️"
        case \.leadershipAndInfluence: return "⭐️"
        case \.courageAndRiskTolerance: return "⚡️"
        case \.spacialNavigationAndOrientation: return "🧭"
        case \.carefulnessAndAttentionToDetail: return "🔎"
        case \.patienceAndPerseverance: return "⏳"
        case \.tinkeringAndFingerPrecision: return "🛠️"
        case \.physicalStrengthAndEndurance: return "💪"
        case \.coordinationAndBalance: return "🤹"
        default: return ""
        }
    }

    private func softRequirement(
        _ keyPath: WritableKeyPath<SoftSkills, Int>,
        _ requiredLevel: Int
    ) -> some View {
        requirementRow(
            label: softLabel(for: keyPath),
            emoji: softPictogram(for: keyPath),
            level: requiredLevel,
            playerLevel: player.softSkills[keyPath: keyPath]
        )
    }

    private func hardRequirementRow(label: String, emoji: String, met: Bool)
        -> some View
    {
        HStack {
            Text(label)
            Spacer()
            Text(emoji)
                .opacity(met ? 1.0 : 0.35)
        }
        .font(.body)
        .foregroundStyle(met ? .primary : .secondary)
        .padding(.horizontal)
    }

    var body: some View {
        ScrollView {
            Text(job.icon)
                .font(.system(size: 96))
                .padding(.top, 16)

            Text(job.id)
                .font(.largeTitle.bold())
                .padding()

            Text(job.summary)
                .font(.body)
                .padding(.horizontal)
                .frame(maxWidth: .infinity ,alignment: .leading)

            HStack(spacing: 12) {
                Text("Income")
                Text("\(job.income) $")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity ,alignment: .leading)
            .padding(.horizontal)
            
            HStack {
                if let tier = job.companyTier {
                    Text("Company tier")
                    Text(tier.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .font(.subheadline)
                .frame(maxWidth: .infinity ,alignment: .leading)
                .padding(.horizontal)

            Text("Requirements")
                .font(.title3)
                .frame(alignment: .leading)

            Divider()
            
            Text("Education:")
                .font(.headline)
                .frame(maxWidth: .infinity ,alignment: .leading)
                .padding()
            
            requirementRow(
                label: job.requirements.education.educationLabel(),
                emoji: "🎓",
                level: job.requirements.education.minEQF,
                playerLevel: player.degrees.last?.eqf ?? 0
            )
            
            
            if requiredSoft.analyticalReasoningAndProblemSolving
                + requiredSoft.creativityAndInsightfulThinking
                + requiredSoft.communicationAndNetworking
                + requiredSoft.leadershipAndInfluence
                + requiredSoft.courageAndRiskTolerance
                + requiredSoft.spacialNavigation
                + requiredSoft.carefulnessAndAttentionToDetail
                + requiredSoft.perseveranceAndGrit
                + requiredSoft.tinkeringAndFingerPrecision
                + requiredSoft.physicalStrength
                + requiredSoft.coordinationAndBalance
                + requiredSoft.resilienceAndEndurance > 0
            {
                Text("Skills:")
                    .font(.headline)
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding()

                softRequirement(\.analyticalReasoningAndProblemSolving, requiredSoft.analyticalReasoningAndProblemSolving)
                softRequirement(\.creativityAndInsightfulThinking, requiredSoft.creativityAndInsightfulThinking)
                softRequirement(\.communicationAndNetworking, requiredSoft.communicationAndNetworking)
                softRequirement(\.leadershipAndInfluence, requiredSoft.leadershipAndInfluence)
                softRequirement(\.courageAndRiskTolerance, requiredSoft.courageAndRiskTolerance)
                softRequirement(\.spacialNavigationAndOrientation, requiredSoft.spacialNavigation)
                softRequirement(\.carefulnessAndAttentionToDetail, requiredSoft.carefulnessAndAttentionToDetail)
                softRequirement(\.patienceAndPerseverance, requiredSoft.perseveranceAndGrit)
                softRequirement(\.tinkeringAndFingerPrecision, requiredSoft.tinkeringAndFingerPrecision)
                softRequirement(\.physicalStrengthAndEndurance, requiredSoft.physicalStrength)
                softRequirement(\.coordinationAndBalance, requiredSoft.coordinationAndBalance)
                softRequirement(\.physicalStrengthAndEndurance, requiredSoft.resilienceAndEndurance)
            }

            
            if !requiredHard.certifications.isEmpty {
                Text("Certifications:")
                    .font(.headline)
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding()
                
                ForEach(requiredHard.certifications, id: \.self) { code in
                    let enumVal = certFrom(raw: code)
                    let owned =
                        enumVal.map {
                            player.hardSkills.certifications.contains($0)
                        } ?? false
                    hardRequirementRow(
                        label: enumVal?.friendlyName ?? code,
                        emoji: enumVal?.pictogram ?? "🎓",
                        met: owned
                    )
                }
            }

            
            if !requiredHard.licenses.isEmpty {
                Text("Licenses:")
                    .font(.headline)
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding()

                ForEach(requiredHard.licenses, id: \.self) { code in
                    let enumVal = licenseFrom(raw: code)
                    let owned =
                        enumVal.map { player.hardSkills.licenses.contains($0) }
                        ?? false
                    hardRequirementRow(
                        label: enumVal?.friendlyName ?? code,
                        emoji: enumVal?.pictogram ?? "📜",
                        met: owned
                    )
                }
            }

            
            if !requiredHard.software.isEmpty {
                Text("Software:")
                    .font(.headline)
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding()

                ForEach(requiredHard.software, id: \.self) { code in
                    let enumVal = softwareFrom(raw: code)
                    let owned =
                        enumVal.map { player.hardSkills.software.contains($0) }
                        ?? false
                    hardRequirementRow(
                        label: enumVal?.rawValue ?? code,
                        emoji: enumVal?.pictogram ?? "💻",
                        met: owned
                    )
                }
            }

            
            if !requiredHard.portfolio.isEmpty {
                Text("Portfolio:")
                    .font(.headline)
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding()

                ForEach(requiredHard.portfolio, id: \.self) { code in
                    let enumVal = portfolioFrom(raw: code)
                    let owned =
                        enumVal.map {
                            player.hardSkills.portfolioItems.contains($0)
                        } ?? false
                    hardRequirementRow(
                        label: enumVal?.rawValue ?? code,
                        emoji: enumVal?.pictogram ?? "📁",
                        met: owned
                    )
                }
            }

            Button {
                player.currentOccupation = job
                showCareersSheet.toggle()
            } label: {
                Text(
                    allRequirementsMet
                        ? "Choose this job" : "Requirements not met"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!allRequirementsMet)
            .opacity(allRequirementsMet ? 1.0 : 0.5)
            .accessibilityHint(
                allRequirementsMet
                    ? "All requirements met" : "Some requirements are not met"
            )
            .padding()

        }
    }
}

#Preview {
    NavigationView {
        JobDetail(
            job: jobExample,
            player: Player(),
            showCareersSheet: .constant(true)
        )
    }
}

