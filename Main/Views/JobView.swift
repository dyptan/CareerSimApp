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

    private var isSimplified: Bool { player.isSimplified }
    private var requiredSoft: SoftSkills { job.requirements.softSkills }
    private var requiredHard: HardSkills { job.requirements.hardSkills }
    private var allRequirementsMet: Bool { job.allRequirementsMet(for: player) }
    private var hireProbability: Double {
        job.hireProbability(for: player, requestedSalary: requestedSalary)
    }

    private var applyButtonLabel: String {
        if player.appliedJobIds.contains(job.applicationKey) { return isFounder ? "Already attempted this year" : "Already applied" }
        if isFounder {
            if !job.experienceMet(for: player) { return "Need more entrepreneurship experience" }
            if player.savings + player.maxVentureLoan <= 0 { return "No savings or income to invest" }
            return "Launch venture 🚀"
        }
        if !allRequirementsMet { return isSimplified ? "Requirements not met" : "Hard requirements not met" }
        return "Apply"
    }

    /// The soft skills that feed the hire-probability skill match, each with the
    /// level the employer looks for. Surfaced in the InfoHint so the list isn't
    /// cluttering the requirements page.
    private var softSkillsClause: String {
        let considered = SoftSkills.skillNames.filter { requiredSoft[keyPath: $0.keyPath] > 0 }
        guard !considered.isEmpty else { return "" }
        let list = considered
            .map { "\($0.pictogram) \($0.label) (target \(requiredSoft[keyPath: $0.keyPath]))" }
            .joined(separator: "\n")
        return "\n\nSoft skills that count toward the skill match (helpful, not required):\n\n\(list)"
    }

    /// Plain-language breakdown of the hire-probability formula with the
    /// player's *current* numbers plugged in. Shown in the InfoHint popover.
    private var hireProbabilityFormulaText: String {
        guard allRequirementsMet else {
            var needs: [String] = []
            if job.educationIsMandatory { needs.append("the required degree") }
            if job.category.requiresCredentials { needs.append("the required license and certification") }
            needs.append("the baseline years of experience")
            return "Hire chance is 0% until you have \(needs.joined(separator: ", ")).\(softSkillsClause)"
        }

        // Breakthrough gate: without the signature title, odds sit at the floor.
        if let key = job.breakthroughFame,
           !player.fameAwards.contains(where: { $0.title == key }) {
            return "This career is gated on a breakthrough achievement. Hire chance stays at the 5% floor until you win a Junior Championship (which banks the “\(key)” title). Earn it and it becomes the single biggest factor in getting signed — worth +\(Int((Job.breakthroughBonus * 100).rounded()))% on top of the usual skill, experience, and fame terms.\(softSkillsClause)"
        }
        let hasBreakthrough = job.breakthroughFame != nil

        let scoredCount = SoftSkills.allAxes.count
        let matched = job.softSkillsHelpfulScore(for: player)
        let skillScore = Double(matched) / Double(scoredCount)
        let skillContribution = skillScore * 0.7
        let prestige = job.relevantPrestigeBonus(for: player)
        let education = job.educationFitTerm(for: player)
        let opportunity = player.difficulty.opportunityBonus
        let network = player.networkBonus(for: job.category)
        let experience = job.experienceFitTerm(for: player)
        let topPosition = job.isTopLeadership
        let fame = player.fameHireBonus(for: job.category, topPosition: topPosition)
        let showFame = fame > 0
        let fameLabel = job.category.fameCategory?.rawValue ?? "general"
        let breakthrough = hasBreakthrough ? Job.breakthroughBonus : 0.0
        let salaryFit = job.salaryAlignmentFactor(requestedSalary: requestedSalary)
        let rawSum = 0.2 + skillContribution + prestige + education + opportunity + network + experience + fame + breakthrough
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

        let expYears = job.expectedYearsExperience
        let playerYears = job.relevantYears(for: player)

        return """
        Formula: (Base 20% + Skill match × 70% + Degree prestige + Experience fit + Network\(showFame ? " + Fame" : "")\(hasBreakthrough ? " + Breakthrough" : "") + Difficulty) × Salary fit

        Your numbers right now:
        • Base: 20%
        • Skill match: \(matched)/\(scoredCount) → \(pct(skillContribution))
        • Degree prestige (\(prestigeLabel)): \(signed(prestige))\(education != 0 ? "\n        • Education fit (below preferred level): \(signed(education))" : "")
        • Experience (\(playerYears)/\(expYears) yr expected): \(signed(experience))
        • Network (\(job.category.rawValue)): \(signed(network))\(showFame ? "\n        • Fame (\(fameLabel))\(topPosition ? " — top role, weighted heavily" : ""): \(signed(fame))" : "")\(hasBreakthrough ? "\n        • Breakthrough (\(job.breakthroughFame ?? "") title): \(signed(breakthrough))" : "")
        • Difficulty bonus: \(signed(opportunity))
        • Salary fit: \(pct(salaryFit))
        Subtotal: \(pct(rawSum)) × \(pct(salaryFit)) = \(pct(raw))
        Final (clamped 5–95%): \(pct(final))
        \(softSkillsClause)
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
            
            Divider()
            Text("Requirements")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()



            Text(job.educationIsMandatory ? "Education:" : "Education (preferred):")
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

            if !job.educationIsMandatory && eduRequired > 0 {
                Text("Not required for this role — but a relevant degree improves your hire chances.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            if let acceptedProfiles = job.requirements.education.acceptedProfiles, !acceptedProfiles.isEmpty {
                let playerProfiles = Set(player.degrees.compactMap { $0.profile })
                let fieldMet = playerProfiles.contains { acceptedProfiles.contains($0) }
                RequirementRow(
                    label: "Field: " + acceptedProfiles.map { $0.rawValue.capitalized }.joined(separator: " / "),
                    emoji: "📚",
                    style: .badge(isMet: fieldMet)
                )
                .foregroundStyle(fieldMet ? .primary : .secondary)
                .padding(.horizontal)
            }

            // Experience is a hard gate at the role's baseline; above that, the
            // employer's tier-scaled preference shapes the hire probability.
            let baseYears = job.requirements.minYearsExperience
            if baseYears > 0 {
                Text("Experience:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                let playerYears = job.relevantYears(for: player)
                let expLabel = job.seniorityPrefix != nil
                    ? "\(baseYears) yr as \(job.baseTitle)"
                    : "\(baseYears) yr in \(job.category.rawValue)"
                RequirementRow(
                    label: expLabel,
                    emoji: "📅",
                    style: .meter(current: playerYears, required: baseYears)
                )
                .foregroundStyle(playerYears >= baseYears ? .primary : .secondary)
                .padding(.horizontal)

                if !isSimplified {
                    if !isFounder {
                        Text("\(baseYears) yr required to qualify — every extra year raises your hire chance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    // Standalone roles credit related industries too — notably,
                    // entrepreneurship experience counts toward Business roles.
                    let credited = job.seniorityPrefix == nil
                        ? job.category.creditedExperienceCategories
                        : []
                    if !credited.isEmpty {
                        let names = credited
                            .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                            .joined(separator: ", ")
                        Text("Your \(names) experience counts toward this too.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
            }

            if !isSimplified && !requiredHard.trainings.isEmpty {
                Text("Trainings:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(Array(requiredHard.trainings).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { training in
                    let owned = player.hardSkills.trainings.contains(training)
                    RequirementRow(label: training.friendlyName, emoji: training.pictogram, style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }
            }

            // Preferred (helpful) credentials — non-gating skill-building programs
            // whose careerBoost covers this field. Never required; holding one
            // meaningfully lifts the hire odds (see Player.trainingCareerBonus).
            let helpfulTrainings = Training.allCases
                .filter { $0.careerBoost?.categories.contains(job.category) == true }
                .sorted { $0.rawValue < $1.rawValue }
            if !isSimplified && !helpfulTrainings.isEmpty {
                Text("Preferred (helpful):")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(helpfulTrainings, id: \.self) { training in
                    let owned = player.hardSkills.trainings.contains(training)
                    RequirementRow(label: training.friendlyName, emoji: training.pictogram, style: .badge(isMet: owned))
                        .foregroundStyle(owned ? .primary : .secondary)
                        .padding(.horizontal)
                }

                Text("Not required — a relevant credential meaningfully raises your hire odds in this field.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            // Breakthrough fame award: the gateway achievement for gated careers
            // (e.g. a junior-competition win for Professional Player). Applies in
            // every mode, so it's shown regardless of simplified/realistic.
            if let key = job.breakthroughFame {
                let held = player.fameAwards.contains { $0.title == key }
                Text("Breakthrough:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                RequirementRow(label: "\(key) title", emoji: "🏅", style: .badge(isMet: held))
                    .foregroundStyle(held ? .primary : .secondary)
                    .padding(.horizontal)

                Text(held
                     ? "This is the single biggest factor in getting signed."
                     : "Win a Junior Championship as a teen to earn this — without it, clubs won't sign you (odds stay at 5%).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            Divider()

            if isFounder {
                founderInvestmentSection
            } else if isSimplified {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Salary:")
                            .font(.title2.bold())
                        Spacer()
                        Text("\(job.income.formatted(.number)) $/yr")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 6) {
                        Text(allRequirementsMet ? "✓ You qualify for this role." : (job.educationIsMandatory ? "🔒 Get the degree and experience first." : "🔒 Get the experience first."))
                            .font(.subheadline)
                            .foregroundStyle(allRequirementsMet ? Color.green : Color.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
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
                investedCapital = min(Double(job.targetCapital ?? 0), Double(player.savings + player.maxVentureLoan))
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
        // You can stake your savings plus a loan of up to 2× income once savings
        // run out (see Player.maxVentureLoan / foundVenture).
        let maxInvestable = Double(player.savings + player.maxVentureLoan)
        let canInvest = maxInvestable > 0
        let borrowed = max(0, Int(investedCapital) - player.savings)
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
                // Guard against a degenerate slider: when the investable span is
                // smaller than the usual 500 increment, a step wider than the
                // range crashes SwiftUI's Slider. Cap the step to the available
                // span (and keep ~10 stops on small ranges) so the range is always
                // valid regardless of how little the player has.
                let step = max(1, min(500, (maxInvestable / 10).rounded()))
                Slider(value: $investedCapital, in: 0...maxInvestable, step: step)
                    .padding(.horizontal)
                HStack {
                    Text("0 $")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("savings \(player.savings.formatted(.number)) $ + loan \(player.maxVentureLoan.formatted(.number)) $")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                if borrowed > 0 {
                    Text("🏦 Borrowing \(borrowed.formatted(.number)) $ against your income — repaid with \(Int(GameConstants.ventureLoanAnnualInterest * 100))% interest, even if the venture flops.")
                        .font(.caption).foregroundStyle(.orange)
                        .padding(.horizontal)
                }
            } else {
                Text("You have no savings or income to invest yet. Earn and save first, then come back to launch.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

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

        Invest more to raise your odds. Succeed and you're in business; fail and you lose your stake.
        """
    }

    // MARK: - Shared apply button

    private func resultMessage(_ result: ApplicationResult) -> String {
        if isFounder {
            return result == .hired ? "🎉 Venture launched!" : "❌ The venture flopped — you lost your stake."
        }
        return result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time."
    }

    private var applyDisabled: Bool {
        if player.appliedJobIds.contains(job.applicationKey) { return true }
        if isFounder { return !job.experienceMet(for: player) || player.savings + player.maxVentureLoan <= 0 }
        return !allRequirementsMet
    }

    private var applyButton: some View {
        Button {
            // Convert defensively: a degenerate slider state could leave the
            // bound value non-finite, and Int(_:) traps on NaN/infinity.
            let capital = investedCapital.isFinite ? Int(investedCapital) : 0
            let salary = requestedSalary.isFinite ? Int(requestedSalary) : job.income
            let success = isFounder
                ? player.foundVenture(job, investedCapital: capital)
                : player.applyForJob(job, requestedSalary: salary)
            if success {
                // Hired (or venture launched): close the careers dialog right away
                // so the player lands back on the game view — the header shows the
                // new job and the celebration plays there.
                applicationResult = .hired
                showCareersSheet = false
            } else {
                // Rejected: keep the dialog open and show the outcome inline so the
                // player can adjust their salary ask or try a different role.
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

