import SwiftUI

struct JobDetail: View {
    var job: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    /// Applying spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    @State private var requestedSalary: Double = 0
    /// The outcome of the attempt just made. Kept only long enough to build the
    /// pop-up's text — the sheet closes, so nothing renders it inline.
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
            return "This career is gated on a breakthrough achievement. Hire chance stays at the 5% floor until you earn the “\(key)” title. \(breakthroughHowTo(key)) Earn it and it becomes the single biggest factor in getting signed — worth +\(Int((Job.breakthroughBonus * 100).rounded()))% on top of the usual skill, experience, and fame terms.\(softSkillsClause)"
        }
        let hasBreakthrough = job.breakthroughFame != nil

        let scoredCount = SoftSkills.allAxes.count
        let matched = job.softSkillsHelpfulScore(for: player)
        let skillScore = Double(matched) / Double(scoredCount)
        let skillContribution = skillScore * 0.7
        let prestige = job.relevantPrestigeBonus(for: player)
        let fit = job.requirementFit(for: player)
        let shortfall = job.educationShortfall(for: player)
        let educationFitLabel = shortfall > 0
            ? "\(shortfall) level\(shortfall == 1 ? "" : "s") below what this role expects"
            : (job.hasAcceptedDegree(for: player) ? "degree in an accepted field" : "degree, but an unrelated field")
        let opportunity = player.difficulty.opportunityBonus
        let network = player.networkBonus(for: job.category)
        let topPosition = job.isTopLeadership
        let fame = player.fameHireBonus(for: job.category, topPosition: topPosition)
        let showFame = fame > 0
        let fameLabel = job.category.fameCategory?.rawValue ?? "general"
        let breakthrough = hasBreakthrough ? Job.breakthroughBonus : 0.0
        let salaryFit = job.salaryAlignmentFactor(requestedSalary: requestedSalary)
        let merit = 0.2 + skillContribution + prestige + opportunity + network + fame + breakthrough
        let climate = player.climate(for: job.industry)
        let raw = merit * fit.factor * salaryFit
        let final = fit.isBlocked ? 0.0 : max(0.05, min(0.95, raw * climate.hireFactor))

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
        Formula: what you bring × how well you meet the requirements × salary fit.

        What you bring:
        • Base: 20%
        • Skill match: \(matched)/\(scoredCount) → \(pct(skillContribution))
        • Degree prestige (\(prestigeLabel)): \(signed(prestige))
        • Network (\(job.category.rawValue)): \(signed(network))\(showFame ? "\n        • Fame (\(fameLabel))\(topPosition ? " — top role, weighted heavily" : ""): \(signed(fame))" : "")\(hasBreakthrough ? "\n        • Breakthrough (\(job.breakthroughFame ?? "") title): \(signed(breakthrough))" : "")
        • Difficulty bonus: \(signed(opportunity))
        Subtotal: \(pct(merit))

        How well you meet the requirements (these multiply — a requirement you
        can't meet at all is ×0, which closes the role):
        • Education (\(educationFitLabel)): ×\(String(format: "%.2f", fit.education))
        • Licences and certificates: ×\(String(format: "%.2f", fit.credentials))
        • Experience (\(playerYears)/\(expYears) yr expected): ×\(String(format: "%.2f", fit.experience))
        • Salary fit: \(pct(salaryFit))

        Then the industry's year:
        • \(climate.icon) \(job.industry.rawValue) is \(climate.rawValue.lowercased()): ×\(String(format: "%.2f", climate.hireFactor))

        \(pct(merit)) × \(String(format: "%.2f", fit.factor)) × \(pct(salaryFit)) × \(String(format: "%.2f", climate.hireFactor)) = \(pct(raw * climate.hireFactor))
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

            let eduPlayerLevel = job.playerEducationLevel(for: player)
            let eduRequired = job.requirements.education.minEQF
            RequirementRow(
                label: job.requirements.education.educationLabel(),
                emoji: "🎓",
                style: .meter(current: eduPlayerLevel, required: eduRequired)
            )
            .foregroundStyle(eduPlayerLevel >= eduRequired ? .primary : .secondary)
            .padding(.horizontal)

            if !job.educationIsMandatory && eduRequired > 0 {
                Text("Not required for this role — but employers weigh it heavily. A degree in an accepted field is worth the most, an unrelated one counts for a little, and falling short of the expected level costs you on every application and every promotion.")
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
                let expLabel = job.isLadderVariant
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
                    Text("\(baseYears) yr required to qualify — every extra year raises your hire chance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Standalone roles credit related industries too — notably,
                    // entrepreneurship experience counts toward Business roles.
                    let credited = !job.isLadderVariant
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
                credentialSection(
                    title: "Trainings:",
                    trainings: Array(requiredHard.trainings).sorted(by: { $0.rawValue < $1.rawValue })
                )
            }

            // Preferred (helpful) credentials — non-gating skill-building programs
            // whose careerBoost covers this field. Never required; holding one
            // meaningfully lifts the hire odds (see Player.trainingCareerBonus).
            let helpfulTrainings = Training.helpfulByCategory[job.category] ?? []
            if !isSimplified && !helpfulTrainings.isEmpty {
                credentialSection(
                    title: "Preferred (helpful):",
                    trainings: helpfulTrainings,
                    footnote: "Not required — a relevant credential meaningfully raises your hire odds in this field."
                )
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
                     : "\(breakthroughHowTo(key)) Without it, you won't be signed (odds stay at 5%).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            Divider()

            if canNegotiate {
                salaryNegotiationSection
            } else {
                postedSalarySection
            }

            applyButton
        }
        .onAppear {
            requestedSalary = Double(job.income)
        }
    }

    /// A titled list of credential rows, marked met/unmet against what the
    /// player holds — used for both the required and the preferred credentials.
    @ViewBuilder
    private func credentialSection(title: String, trainings: [Training], footnote: String? = nil) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

        ForEach(trainings, id: \.self) { training in
            let owned = player.hardSkills.trainings.contains(training)
            RequirementRow(label: training.friendlyName, emoji: training.pictogram, style: .badge(isMet: owned))
                .foregroundStyle(owned ? .primary : .secondary)
                .padding(.horizontal)
        }

        if let footnote {
            Text(footnote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    // MARK: - Employee application (pay)

    /// Whether this application offers a salary slider. Simplified mode never
    /// negotiates — it keeps the money simple — and neither do roles that pay a
    /// posted rate (see `Job.salaryIsNegotiable`).
    private var canNegotiate: Bool { !isSimplified && job.salaryIsNegotiable }

    /// Pay for a role you take at the advertised rate. Still shows the hire
    /// odds in the realistic modes — what you can't argue about, you can still
    /// weigh.
    private var postedSalarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Salary:")
                    .font(.title2.bold())
                Spacer()
                Text("\(job.income.formatted(.number)) $/yr")
                    .font(.headline)
            }
            .padding(.horizontal)

            Text(isSimplified
                 ? "The rate for this role."
                 : "This role pays the going rate — there's no offer to argue over.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            HStack(spacing: 6) {
                Text(allRequirementsMet ? "✓ You qualify for this role." : (job.educationIsMandatory ? "🔒 Get the degree and experience first." : "🔒 Get the experience first."))
                    .font(.subheadline)
                    .foregroundStyle(allRequirementsMet ? Color.green : Color.secondary)
                Spacer()
            }
            .padding(.horizontal)

            if !isSimplified {
                hireProbabilityRow
            }
        }
        .padding(.vertical)
    }

    /// The odds readout, shared by both pay sections so it reads the same either
    /// way.
    private var hireProbabilityRow: some View {
        HStack(spacing: 6) {
            Text("Hire probability:")
            InfoHint(
                title: "How hire probability is calculated",
                message: hireProbabilityFormulaText
            )
            Spacer()
            Text("\(Int(hireProbability * 100)) %")
                .font(.headline)
                .foregroundStyle(Color.forOdds(hireProbability))
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

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

            hireProbabilityRow
        }
        .padding(.vertical)
    }

    // MARK: - Shared apply button

    /// How the player earns a gated career's breakthrough award — the rare
    /// achievement that unlocks it. Keyed by the award title so the copy stays
    /// accurate as new star tracks are added.
    private func breakthroughHowTo(_ key: String) -> String {
        switch key {
        case "Junior Champion": return "Win a Junior Championship as a teen — train a sport for years to raise your odds."
        case "Breakout Role":   return "Chase a Breakout Role under Projects — it takes years and high performing skills."
        case "Hit Record":      return "Chase a Hit Single under Projects — it takes years and high performing skills."
        default:                return "Earn the “\(key)” title first."
        }
    }

    /// What to say on a win. The header already shows the new job, so this says
    /// what it means rather than repeating the title.
    private var successMessage: String {
        "You start as \(job.displayTitle) on \(Int(requestedSalary).formatted(.number)) $ a year."
    }

    private func resultMessage(_ result: ApplicationResult) -> String {
        result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time."
    }

    /// Explains *why* an application was turned down and what the player can do
    /// about it — a rejection is otherwise a silent dead end. Requirements are
    /// already met (the button gates on that), so a "no" is either the
    /// breakthrough gate, a too-high salary ask, or simply losing the odds roll;
    /// this names the dominant lever and points at the ⓘ breakdown. Simplified
    /// mode never rejects a qualified applicant, so this only fires in the
    /// realistic settings.
    private var rejectionAdvice: String? {
        guard applicationResult == .rejected else { return nil }
        func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }

        // The breakthrough gate (e.g. a pro-player role needing a junior title)
        // pins odds at the 5% floor — by far the likeliest reason for a "no", so
        // call it out first.
        if let key = job.breakthroughFame,
           !player.fameAwards.contains(where: { $0.title == key }) {
            return "Employers here look for the “\(key)” title — earn it first to unlock this career."
        }

        return "Your odds were \(pct(hireProbability)) and the roll didn't land. Try again next year."
    }

    private var applyDisabled: Bool { !allRequirementsMet }

    private var applyButton: some View {
        Button {
            // Convert defensively: a degenerate slider state could leave the
            // bound value non-finite, and Int(_:) traps on NaN/infinity.
            let salary = requestedSalary.isFinite ? Int(requestedSalary) : job.income
            let success = player.applyForJob(job, requestedSalary: salary)
            // Applying is how the year was spent, offer or no offer, so the
            // answer is a pop-up on the game view rather than a banner in a
            // sheet the player is about to leave. A "no" still explains itself
            // and what to change before next year.
            applicationResult = success ? .hired : .rejected
            player.reportApplicationOutcome(
                title: resultMessage(success ? .hired : .rejected),
                message: rejectionAdvice ?? successMessage
            )
            onCommit()
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
    NavigationStack {
        JobDetail(
            job: jobExample,
            player: Player(),
            showCareersSheet: .constant(true)
        )
    }
}

