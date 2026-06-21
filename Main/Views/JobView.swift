import SwiftUI

struct JobDetail: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    @State private var requestedSalary: Double = 0
    @State private var investedCapital: Double = 0
    @State private var applicationResult: ApplicationResult? = nil

    enum ApplicationResult { case hired, rejected }

    private var sliderMin: Double { Double(job.income) * 0.5 }
    private var sliderMax: Double { Double(job.income) * 2.0 }

    private var requiredSoft: SoftSkills { job.requirements.softSkills }
    private var requiredHard: HardSkills { job.effectiveRequirements.hardSkills }
    private var allRequirementsMet: Bool { job.allRequirementsMet(for: player) }
    private var hireProbability: Double {
        job.hireProbability(for: player, requestedSalary: requestedSalary)
    }

    private var applyButtonLabel: String {
        if player.appliedJobIds.contains(job.id) { return isFounder ? "Already attempted this year" : "Already applied" }
        if isFounder {
            if !job.experienceMet(for: player) { return "Need more entrepreneurship experience" }
            if player.savings <= 0 { return "No savings to invest" }
            return "Launch venture 🚀"
        }
        if !allRequirementsMet { return "Hard requirements not met" }
        return "Apply"
    }

    /// Plain-language breakdown of the hire-probability formula with the
    /// player's *current* numbers plugged in. Shown in the InfoHint popover.
    private var hireProbabilityFormulaText: String {
        guard allRequirementsMet else {
            return "Hire chance is 0% until every required degree, license, \(job.companyTier.hiringSignal == .credentials ? "certification" : "portfolio item"), and year of industry experience is in place."
        }

        let scoredCount = SoftSkills.allAxes.count
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
            Text("Hard requirements")
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

            let yearsRequired = job.requirements.minYearsExperience
            if yearsRequired > 0 {
                Text("Experience:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                let playerYears = player.experience[job.category] ?? 0
                RequirementRow(
                    label: "\(yearsRequired) yr in \(job.category.rawValue)",
                    emoji: "📅",
                    style: .meter(current: playerYears, required: yearsRequired)
                )
                .foregroundStyle(playerYears >= yearsRequired ? .primary : .secondary)
                .padding(.horizontal)
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

            let requiredSkills = SoftSkills.skillNames.filter { requiredSoft[keyPath: $0.keyPath] > 0 }
            if !requiredSkills.isEmpty {
                Text("Soft requirements")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Text("Helpful but not required — they boost your hire probability.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ForEach(requiredSkills, id: \.label) { skill in
                    let required = requiredSoft[keyPath: skill.keyPath]
                    let playerValue = player.softSkills[keyPath: skill.keyPath]
                    RequirementRow(label: skill.label, emoji: skill.pictogram, style: .meter(current: playerValue, required: required))
                        .foregroundStyle(playerValue >= required ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            Divider()

            if isFounder {
                founderInvestmentSection
            } else {
                salaryNegotiationSection
            }

            if let result = applicationResult {
                Text(resultMessage(result))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }

            applyButton
        }
        .onAppear {
            requestedSalary = Double(job.income)
            if isFounder {
                investedCapital = min(Double(job.targetCapital ?? 0), Double(player.savings))
            }
        }
    }

    // MARK: - Employee application (salary negotiation)

    private var salaryNegotiationSection: some View {
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
        }
        .padding(.vertical)
    }

    // MARK: - Founder launch (capital investment)

    private var isFounder: Bool { job.isEntrepreneurial }

    private var founderProbability: Double {
        job.founderSuccessProbability(for: player, investedCapital: Int(investedCapital))
    }

    private var founderInvestmentSection: some View {
        let target = job.targetCapital ?? 0
        let canInvest = player.savings > 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("Launch your venture")
                .font(.title2.bold())
                .padding(.horizontal)

            HStack {
                Text("Capital to invest:")
                Spacer()
                Text("\(Int(investedCapital).formatted(.number)) $")
                    .font(.headline)
            }
            .padding(.horizontal)

            if canInvest {
                Slider(value: $investedCapital, in: 0...Double(player.savings), step: 500)
                    .padding(.horizontal)
                HStack {
                    Text("0 $")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("your savings: \(player.savings.formatted(.number)) $")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            } else {
                Text("You have no savings to invest yet. Earn and save first, then come back to launch.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            HStack {
                Text("Recommended capital:")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(target.formatted(.number)) $")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            HStack(spacing: 6) {
                Text("Success chance:")
                InfoHint(
                    title: "How founding works",
                    message: founderFormulaText
                )
                Spacer()
                Text("\(Int(founderProbability * 100)) %")
                    .font(.headline)
                    .foregroundStyle(founderProbability >= 0.6 ? .green : founderProbability >= 0.3 ? .orange : .red)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Text("If the venture fails, you keep half of what you put in.")
                .font(.caption2).foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private var founderFormulaText: String {
        guard job.experienceMet(for: player) else {
            return "You need more years as an entrepreneur before you can take on this venture. Start with a smaller one first."
        }
        let target = (job.targetCapital ?? 0).formatted(.number)
        return """
        Your odds come mostly from how much capital you put in versus the \(target) $ this venture really needs, plus your founder skills (Risk-Taker 🎲, Visionary 🔭, Persuader 💬).

        Invest more to raise your odds. Succeed and you're in business; fail and you keep half your stake.
        """
    }

    // MARK: - Shared apply button

    private func resultMessage(_ result: ApplicationResult) -> String {
        if isFounder {
            return result == .hired ? "🎉 Venture launched!" : "❌ The venture flopped — you kept half your stake."
        }
        return result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time."
    }

    private var applyDisabled: Bool {
        if player.appliedJobIds.contains(job.id) { return true }
        if isFounder { return !job.experienceMet(for: player) || player.savings <= 0 }
        return !allRequirementsMet
    }

    private var applyButton: some View {
        Button {
            let success = isFounder
                ? player.foundVenture(job, investedCapital: Int(investedCapital))
                : player.applyForJob(job, requestedSalary: Int(requestedSalary))
            if success {
                applicationResult = .hired
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showCareersSheet.toggle()
                }
            } else {
                applicationResult = .rejected
            }
        } label: {
            Text(applyButtonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(applyDisabled)
        .opacity(applyDisabled ? 0.5 : 1.0)
        .padding()
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

