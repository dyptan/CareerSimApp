import SwiftUI

struct JobDetail: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    @State private var requestedSalary: Double = 0
    @State private var applicationResult: ApplicationResult? = nil

    enum ApplicationResult { case hired, rejected }

    private var sliderMin: Double { Double(job.income) * 0.5 }
    private var sliderMax: Double { Double(job.income) * 2.0 }

    private var requiredSoft: SoftSkills {
        job.requirements.softSkills
    }
    private var requiredHard: HardSkills {
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

    private var softSkillsHelpfulScore: Int {
        let p = player.softSkills
        let r = requiredSoft
        var score = 0
        if p.analyticalReasoningAndProblemSolving >= r.analyticalReasoningAndProblemSolving { score += 1 }
        if p.creativityAndInsightfulThinking >= r.creativityAndInsightfulThinking { score += 1 }
        if p.communicationAndNetworking >= r.communicationAndNetworking { score += 1 }
        if p.leadershipAndInfluence >= r.leadershipAndInfluence { score += 1 }
        if p.visionaryThinkingAndAmbition >= r.visionaryThinkingAndAmbition { score += 1 }
        if p.spacialNavigationAndOrientation >= r.spacialNavigationAndOrientation { score += 1 }
        if p.carefulnessAndAttentionToDetail >= r.carefulnessAndAttentionToDetail { score += 1 }
        if p.tinkeringAndFingerPrecision >= r.tinkeringAndFingerPrecision { score += 1 }
        if p.resilienceAndEndurance >= r.resilienceAndEndurance { score += 1 }
        if p.outdoorAndWeatherResilience >= r.outdoorAndWeatherResilience { score += 1 }
        if p.stressResistanceAndEmotionalRegulation >= r.stressResistanceAndEmotionalRegulation { score += 1 }
        if p.collaborationAndTeamwork >= r.collaborationAndTeamwork { score += 1 }
        if p.timeManagementAndPlanning >= r.timeManagementAndPlanning { score += 1 }
        if p.selfDisciplineAndPerseverance >= r.selfDisciplineAndPerseverance { score += 1 }
        if p.presentationAndStorytelling >= r.presentationAndStorytelling { score += 1 }
        return score
    }

    private var salaryAlignmentFactor: Double {
        let ratio = requestedSalary / Double(job.annualIncome)
        if ratio <= 1.0 { return 1.0 }
        // asking more than company budget: probability drops steeply above 15% excess
        return max(0.0, 1.0 - (ratio - 1.0) * 3.0)
    }

    private var hireProbability: Double {
        guard allRequirementsMet else { return 0.0 }
        let skillScore = Double(softSkillsHelpfulScore) / 15.0
        let raw = (0.2 + skillScore * 0.7) * salaryAlignmentFactor
        return max(0.05, min(0.95, raw))
    }

    private var hardSkillsMet: Bool {
        let certsOK = requiredHard.certifications.allSatisfy { code in
            guard let enumVal = certFrom(raw: code.rawValue) else { return false }
            return player.hardSkills.certifications.contains(enumVal)
        }
        let licensesOK = requiredHard.licenses.allSatisfy { code in
            guard let enumVal = licenseFrom(raw: code.rawValue) else { return false }
            return player.hardSkills.licenses.contains(enumVal)
        }
        let softwareOK = requiredHard.software.allSatisfy { code in
            guard let enumVal = softwareFrom(raw: code.rawValue) else { return false }
            return player.hardSkills.software.contains(enumVal)
        }
        let portfolioOK = requiredHard.portfolioItems.allSatisfy { code in
            guard let enumVal = portfolioFrom(raw: code.rawValue) else { return false }
            return player.hardSkills.portfolioItems.contains(enumVal)
        }
        return certsOK && licensesOK && softwareOK && portfolioOK
    }

    private var allRequirementsMet: Bool {
        // Emphasize degree + hard skills; soft skills are helpful only
        educationMet && hardSkillsMet
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
                Text("Market median")
                Text("\(job.income) $")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            HStack {
                Text("Company")
                Text(job.companyTier.displayName)
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

            Divider()
            Text("Requirements")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            
            
            Text("Education:")
                .font(.headline)
                .frame(maxWidth: .infinity ,alignment: .leading)
                .padding()
            
            let eduPlayerLevel = player.degrees.last?.eqf ?? 0
            let eduRequired = job.requirements.education.minEQF
            RequirementRow(
                label: job.requirements.education.educationLabel(),
                emoji: "🎓",
                style: .meter(current: eduPlayerLevel, required: eduRequired)
            )
            .foregroundStyle(eduPlayerLevel >= eduRequired ? .primary : .secondary)
            .padding(.horizontal)

            let requiredSkills = SoftSkills.skillNames.filter { requiredSoft[keyPath: $0.keyPath] > 0 }
            if !requiredSkills.isEmpty {
                Text("Skills:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(requiredSkills, id: \.label) { skill in
                    let required = requiredSoft[keyPath: skill.keyPath]
                    let playerValue = player.softSkills[keyPath: skill.keyPath]
                    RequirementRow(label: skill.label, emoji: skill.pictogram, style: .meter(current: playerValue, required: required))
                        .foregroundStyle(playerValue >= required ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            
            if !requiredHard.certifications.isEmpty {
                Text("Certifications:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(Array(requiredHard.certifications).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { code in
                    let enumVal = certFrom(raw: code.rawValue)
                    let owned = enumVal.map { player.hardSkills.certifications.contains($0) } ?? false
                    RequirementRow(label: enumVal?.friendlyName ?? code.rawValue, emoji: enumVal?.pictogram ?? "🎓", style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            if !requiredHard.licenses.isEmpty {
                Text("Licenses:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(Array(requiredHard.licenses).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { license in
                    let owned = player.hardSkills.licenses.contains(license)
                    RequirementRow(label: license.friendlyName, emoji: license.pictogram, style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            if !requiredHard.software.isEmpty {
                Text("Software:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(Array(requiredHard.software).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { software in
                    let owned = player.hardSkills.software.contains(software)
                    RequirementRow(label: software.rawValue, emoji: software.pictogram, style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            if !requiredHard.portfolioItems.isEmpty {
                Text("Portfolio:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(Array(requiredHard.portfolioItems).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { project in
                    let owned = player.hardSkills.portfolioItems.contains(project)
                    RequirementRow(label: project.rawValue, emoji: project.pictogram, style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Salary negotiation")
                    .font(.title2.bold())
                    .padding(.horizontal)

                HStack {
                    Text("Your ask:")
                    Spacer()
                    Text("\(Int(requestedSalary).formatted(.number)) $")
                        .font(.headline)
                }
                .padding(.horizontal)

                Slider(value: $requestedSalary, in: sliderMin...sliderMax, step: 500)
                    .padding(.horizontal)

                HStack {
                    Text("\(Int(sliderMin).formatted(.number)) $")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(sliderMax).formatted(.number)) $")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                HStack {
                    Text("Hire probability:")
                    Spacer()
                    Text("\(Int(hireProbability * 100)) %")
                        .font(.headline)
                        .foregroundStyle(hireProbability >= 0.6 ? .green : hireProbability >= 0.3 ? .orange : .red)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                if let result = applicationResult {
                    Text(result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time.")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .padding(.vertical)

            Button {
                player.appliedJobIds.insert(job.id)
                if Double.random(in: 0...1) < hireProbability {
                    var hired = job
                    hired.annualIncome = Int(requestedSalary)
                    player.currentOccupation = hired
                    applicationResult = .hired
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showCareersSheet.toggle()
                    }
                } else {
                    applicationResult = .rejected
                }
            } label: {
                Text("Apply")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!allRequirementsMet || player.appliedJobIds.contains(job.id))
            .opacity(allRequirementsMet && !player.appliedJobIds.contains(job.id) ? 1.0 : 0.5)
            .padding()
        }
        .onAppear {
            requestedSalary = Double(job.income)
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

