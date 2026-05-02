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

    private var requiredSoft: SoftSkills { job.requirements.softSkills }
    private var requiredHard: HardSkills { job.requirements.hardSkills }
    private var allRequirementsMet: Bool { job.allRequirementsMet(for: player) }
    private var hireProbability: Double {
        job.hireProbability(for: player, requestedSalary: requestedSalary)
    }

    /// Plain-language breakdown of the hire-probability formula with the
    /// player's *current* numbers plugged in. Shown in the InfoHint popover.
    private var hireProbabilityFormulaText: String {
        guard allRequirementsMet else {
            return "Hire chance is 0% until every required degree, license, and \(job.companyTier.hiringSignal == .credentials ? "certification" : "portfolio item") is in place."
        }

        let scoredCount = 15
        let matched = job.softSkillsHelpfulScore(for: player)
        let skillScore = Double(matched) / Double(scoredCount)
        let skillContribution = skillScore * 0.7
        let prestige = job.relevantPrestigeBonus(for: player)
        let tier = job.companyTier.hireDifficulty
        let salaryFit = job.salaryAlignmentFactor(requestedSalary: requestedSalary)
        let rawSum = 0.2 + skillContribution + prestige + tier
        let raw = rawSum * salaryFit
        let final = max(0.05, min(0.95, raw))

        func pct(_ v: Double) -> String {
            "\(Int((v * 100).rounded()))%"
        }
        func signed(_ v: Double) -> String {
            let s = Int((v * 100).rounded())
            return s >= 0 ? "+\(s)%" : "\(s)%"
        }

        let topPrestige = (player.degrees.map { $0.tier.prestige }.max() ?? 0)
        let prestigeLabel: String = {
            switch topPrestige {
            case 3: return "Elite"
            case 2: return "State"
            case 1: return "Community"
            default: return "no degree"
            }
        }()

        return """
        Formula: (Base 20% + Skill match × 70% + Degree prestige + Company tier) × Salary fit

        Your numbers right now:
        • Base: 20%
        • Skill match: \(matched)/\(scoredCount) → \(pct(skillContribution))
        • Degree prestige (\(prestigeLabel)): \(signed(prestige))
        • Company tier (\(job.companyTier.displayName)): \(signed(tier))
        • Salary fit: \(pct(salaryFit))
        Subtotal: \(pct(rawSum)) × \(pct(salaryFit)) = \(pct(raw))
        Final (clamped 5–95%): \(pct(final))
        """
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

                ForEach(Array(requiredHard.certifications).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { cert in
                    let owned = player.hardSkills.certifications.contains(cert)
                    RequirementRow(label: cert.friendlyName, emoji: cert.pictogram, style: .badge(isMet: owned))
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

                HStack(spacing: 6) {
                    Text("Hire probability:")
                    InfoHint(
                        title: "How hire probability is calculated",
                        message: hireProbabilityFormulaText
                    )
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
                if player.applyForJob(job, requestedSalary: Int(requestedSalary)) {
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

