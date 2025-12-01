import SwiftUI

extension SoftSkills {
    static func pictogram(forLabel label: String) -> String? {
        skillNames.first(where: { $0.label == label })?.pictogram
    }
    static func label(forKeyPath keyPath: WritableKeyPath<SoftSkills, Int>)
        -> String?
    {
        skillNames.first(where: { $0.keyPath == keyPath })?.label
    }
    static func pictogram(forKeyPath keyPath: WritableKeyPath<SoftSkills, Int>)
        -> String?
    {
        skillNames.first(where: { $0.keyPath == keyPath })?.pictogram
    }
}

struct JobView: View {
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
    
    private func portfolioFrom(raw: String) -> PortfolioItem? {
        PortfolioItem(rawValue: raw)
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

    private var softSkillsMet: Bool {
        let p = player.softSkills
        let r = requiredSoft
        return
            p.analyticalReasoningAndProblemSolving
            >= r.analyticalReasoningAndProblemSolving
            && p.creativityAndInsightfulThinking
                >= r.creativityAndInsightfulThinking
            && p.communicationAndNetworking >= r.communicationAndNetworking
            && p.leadershipAndInfluence >= r.leadershipAndInfluence
            && p.courageAndRiskTolerance >= r.courageAndRiskTolerance
            && p.spacialNavigation >= r.spacialNavigation
            && p.carefulnessAndAttentionToDetail
                >= r.carefulnessAndAttentionToDetail
            && p.perseveranceAndGrit >= r.perseveranceAndGrit
            && p.tinkeringAndFingerPrecision >= r.tinkeringAndFingerPrecision
            && p.physicalStrength >= r.physicalStrength
            && p.coordinationAndBalance >= r.coordinationAndBalance
            && p.resilienceAndEndurance >= r.resilienceAndEndurance
    }

    private var hardSkillsMet: Bool {
        // Certifications
        let certsOK = requiredHard.certifications.allSatisfy { code in
            guard let enumVal = certFrom(raw: code) else { return false }
            return player.hardSkills.certifications.contains(enumVal)
        }
        // Licenses
        let licensesOK = requiredHard.licenses.allSatisfy { code in
            guard let enumVal = licenseFrom(raw: code) else { return false }
            return player.hardSkills.licenses.contains(enumVal)
        }
        // Software
        let softwareOK = requiredHard.software.allSatisfy { code in
            guard let enumVal = softwareFrom(raw: code) else { return false }
            return player.hardSkills.software.contains(enumVal)
        }
        // Portfolio
        let portfolioOK = requiredHard.portfolio.allSatisfy { code in
            guard let enumVal = portfolioFrom(raw: code) else { return false }
            return player.hardSkills.portfolioItems.contains(enumVal)
        }
        return certsOK && licensesOK && softwareOK && portfolioOK
    }

    private var allRequirementsMet: Bool {
        educationMet && softSkillsMet && hardSkillsMet
    }

//    private func formattedIncome(_ dollars: Int) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencyCode = "USD"
//        formatter.maximumFractionDigits = 0
//        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(dollars)"
//    }

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

    private func softRequirement(
        _ keyPath: WritableKeyPath<SoftSkills, Int>,
        _ requiredLevel: Int
    ) -> some View {
        requirementRow(
            label: SoftSkills.label(forKeyPath: keyPath) ?? "",
            emoji: SoftSkills.pictogram(forKeyPath: keyPath) ?? "",
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

//    private func labelBox<T: View>(title: String, content: T) -> some View {
//        VStack(spacing: 6) {
//            Text(title)
//                .font(.caption)
//                .foregroundStyle(.secondary)
//            content
//                .font(.body)
//        }
//        .padding(12)
//        .frame(maxWidth: .infinity)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }

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

            HStack(spacing: 16) {
                Text("Income")
                Text("\(job.income) $")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity ,alignment: .leading)
            .padding(.horizontal)
           

            Text("Requirements")
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity ,alignment: .leading)

            Divider()
            
            requirementRow(
                label: job.requirements.education.educationLabel(),
                emoji: "🎓",
                level: job.requirements.education.minEQF,
                playerLevel: player.degrees.last?.eqf ?? 0
            )
            
            if let accepted = job.requirements.education.acceptedProfiles,
                !accepted.isEmpty
            {
                let playerProfiles = player.degrees.compactMap { $0.profile }
                let met =
                    !playerProfiles.isEmpty
                    && playerProfiles.contains(where: { accepted.contains($0) })
                HStack {
                    Text(
                        "Accepted profiles: \(accepted.map { $0.rawValue.capitalized }.joined(separator: ", "))"
                    )
                    Spacer()
                    Text(met ? "✅" : "❌")
                }
                .font(.subheadline)
                .foregroundStyle(met ? .primary : .secondary)
                .padding()
            }
            
            softRequirement(
                \.analyticalReasoningAndProblemSolving,
                requiredSoft.analyticalReasoningAndProblemSolving
            )
            softRequirement(
                \.creativityAndInsightfulThinking,
                requiredSoft.creativityAndInsightfulThinking
            )
            softRequirement(
                \.communicationAndNetworking,
                requiredSoft.communicationAndNetworking
            )
            softRequirement(
                \.leadershipAndInfluence,
                requiredSoft.leadershipAndInfluence
            )
            softRequirement(
                \.courageAndRiskTolerance,
                requiredSoft.courageAndRiskTolerance
            )
            softRequirement(\.spacialNavigation, requiredSoft.spacialNavigation)
            softRequirement(
                \.carefulnessAndAttentionToDetail,
                requiredSoft.carefulnessAndAttentionToDetail
            )
            softRequirement(
                \.perseveranceAndGrit,
                requiredSoft.perseveranceAndGrit
            )
            softRequirement(
                \.tinkeringAndFingerPrecision,
                requiredSoft.tinkeringAndFingerPrecision
            )
            softRequirement(\.physicalStrength, requiredSoft.physicalStrength)
            softRequirement(
                \.coordinationAndBalance,
                requiredSoft.coordinationAndBalance
            )
            softRequirement(
                \.resilienceAndEndurance,
                requiredSoft.resilienceAndEndurance
            )

            Spacer()
            // Certifications
            if !requiredHard.certifications.isEmpty {
                Text("Certifications")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding(.horizontal)
                
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

            // Licenses
            if !requiredHard.licenses.isEmpty {
                Text("Licenses")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding(.horizontal)

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

            // Software
            if !requiredHard.software.isEmpty {
                Text("Software")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding(.horizontal)

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

            // Portfolio
            if !requiredHard.portfolio.isEmpty {
                Text("Portfolio")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity ,alignment: .leading)
                    .padding(.horizontal)

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
        JobView(
            job: jobExample,
            player: Player(),
            showCareersSheet: .constant(true)
        )
    }
}
