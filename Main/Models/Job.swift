import Foundation


struct Job: Identifiable, Codable, Hashable {
    let id: String
    let category: JobCategory
    let income: Int            // base/reference salary shown in job listings
    let summary: String
    let icon: String
    let requirements: Requirements
    var annualIncome: Int      // actual pay locked in when the job was taken
    /// For entrepreneurial roles: the capital a founder ideally puts up to launch
    /// this venture. Drives success odds (see `founderSuccessProbability`).
    /// `nil` for ordinary employee jobs.
    let targetCapital: Int?

    init(id: String, category: JobCategory, income: Int, summary: String, icon: String,
         requirements: Requirements, targetCapital: Int? = nil) {
        self.id = id
        self.category = category
        self.income = income
        self.summary = summary
        self.icon = icon
        self.requirements = requirements
        self.targetCapital = targetCapital
        let variance = category.salaryVariance
        let factor = Double.random(in: (1.0 - variance)...(1.0 + variance))
        self.annualIncome = Int(Double(income) * factor)
    }

    struct Requirements: Codable, Hashable {
        let education: Education
        let softSkills: SoftSkills
        let hardSkills: HardSkills
        /// Minimum years of prior experience in the job's industry (category).
        let minYearsExperience: Int

        init(education: Education,
             softSkills: SoftSkills,
             hardSkills: HardSkills,
             minYearsExperience: Int = 0) {
            self.education = education
            self.softSkills = softSkills
            self.hardSkills = hardSkills
            self.minYearsExperience = minYearsExperience
        }

        enum CodingKeys: String, CodingKey {
            case education, softSkills, hardSkills, minYearsExperience
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.education = try c.decode(Education.self, forKey: .education)
            self.softSkills = try c.decode(SoftSkills.self, forKey: .softSkills)
            self.hardSkills = try c.decode(HardSkills.self, forKey: .hardSkills)
            self.minYearsExperience = try c.decodeIfPresent(Int.self, forKey: .minYearsExperience) ?? 0
        }

        struct Education: Codable, Hashable {
            let minEQF: Int
            let acceptedProfiles: [TertiaryProfile]?

            enum CodingKeys: String, CodingKey {
                case minEQF
                case acceptedProfiles
            }

            init(minEQF: Int, acceptedProfiles: [TertiaryProfile]?) {
                self.minEQF = minEQF
                self.acceptedProfiles = acceptedProfiles
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.minEQF = try container.decode(Int.self, forKey: .minEQF)
                if let raw = try container.decodeIfPresent([String].self, forKey: .acceptedProfiles) {
                    self.acceptedProfiles = raw.compactMap { TertiaryProfile(rawValue: $0) }
                } else {
                    self.acceptedProfiles = nil
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(minEQF, forKey: .minEQF)
                if let profiles = acceptedProfiles {
                    try container.encode(profiles.map { $0.rawValue }, forKey: .acceptedProfiles)
                }
            }

            func educationLabel() -> String {
                switch minEQF {
                case ..<1: return "Primary school"
                case 1: return "Primary school"
                case 2: return "Middle school"
                case 3: return "High school"
                case 4: return "College / Vocational"
                case 5: return "University — Bachelor's"
                case 6: return "University — Master's"
                case 7: return "Doctorate"
                default: return "Doctorate+"
                }
            }
        }
    }
}

// MARK: - Job evaluation (player fit, hire probability)

extension Job {
    /// Soft-skill keypaths counted by the hire-probability score, derived from
    /// the single source of truth (`SoftSkills.allAxes`). The hire-probability
    /// divisor uses `.count`, so new axes are scored automatically.
    private static let scoredSoftSkills: [WritableKeyPath<SoftSkills, Int>] =
        SoftSkills.allAxes.filter(\.isScored).map(\.keyPath)

    /// Careers whose hiring hinges on a breakthrough fame award — a specific
    /// achievement (won in a competition) that is *the* gateway into the field.
    /// Keyed by base title → the required `FameAward.title`. Without it, hire
    /// odds sit at the floor even for a strong applicant; with it, a large bonus
    /// makes it the dominant hiring factor. The Professional Player track is
    /// gated on the "Junior Champion" title from the teen `Junior Championship`.
    static let breakthroughFameByRole: [String: String] = [
        "Player": "Junior Champion"
    ]

    /// The breakthrough fame award this role requires, or nil for ordinary
    /// roles. Keyed by `baseTitle`, so every rung of a ladder shares it.
    var breakthroughFame: String? {
        Job.breakthroughFameByRole[baseTitle]
    }

    /// Hire-probability bonus once the player holds this role's breakthrough
    /// fame award. Large enough to dominate the formula — it is the single
    /// most important factor for a gated career.
    static let breakthroughBonus: Double = 0.40

    func educationMet(for player: Player) -> Bool {
        let playerEQF = player.degrees.last?.eqf ?? 0
        guard playerEQF >= requirements.education.minEQF else { return false }
        if let accepted = requirements.education.acceptedProfiles, !accepted.isEmpty {
            let playerProfiles = player.degrees.compactMap { $0.profile }
            if playerProfiles.isEmpty { return false }
            return playerProfiles.contains(where: { accepted.contains($0) })
        }
        return true
    }

    func softSkillsHelpfulScore(for player: Player) -> Int {
        Self.scoredSoftSkills.reduce(0) { score, kp in
            score + (player.softSkills[keyPath: kp] >= requirements.softSkills[keyPath: kp] ? 1 : 0)
        }
    }

    /// Years of the player's experience relevant to this role: same-role tenure
    /// for a rung on a seniority ladder (so unrelated jobs in the industry don't
    /// qualify you for a promotion), or accumulated whole-industry years for a
    /// standalone role (entry-level, or a top capstone with no junior rung).
    /// Standalone roles credit related industries too — notably, entrepreneurship
    /// experience counts toward Business roles (see `Player.industryExperience`).
    func relevantYears(for player: Player) -> Int {
        if seniorityPrefix != nil {
            return player.experienceByRole[baseTitle] ?? 0
        }
        return player.industryExperience(for: category)
    }

    /// Years of experience this role expects — its catalog baseline
    /// (`minYearsExperience`). Zero when the role has no experience baseline.
    var expectedYearsExperience: Int {
        requirements.minYearsExperience
    }

    /// Whether the player meets the role's *baseline* experience
    /// (`minYearsExperience`). A hard gate in every mode — you can't be hired (or
    /// found a venture) below the baseline. Above it, the tier-scaled
    /// `experienceFitTerm` rewards extra years probabilistically.
    func experienceMet(for player: Player) -> Bool {
        let required = requirements.minYearsExperience
        guard required > 0 else { return true }
        return relevantYears(for: player) >= required
    }

    /// Additive hire-probability adjustment from how the player's relevant
    /// experience compares with what this employer expects — a *soft* factor,
    /// not a gate. Meeting the (tier-scaled) expectation is neutral; falling
    /// short penalises, down to −0.45 with no experience at all for a senior
    /// posting; a seasoned, over-experienced applicant earns a small edge
    /// (up to +0.10).
    func experienceFitTerm(for player: Player) -> Double {
        let expected = expectedYearsExperience
        guard expected > 0 else { return 0.0 }
        let ratio = Double(relevantYears(for: player)) / Double(expected)
        if ratio >= 1.0 {
            return min(0.10, (ratio - 1.0) * 0.10)
        }
        return (ratio - 1.0) * 0.45
    }

    func hardSkillsMet(for player: Player) -> Bool {
        let req = requirements.hardSkills
        let held = player.hardSkills.trainings
        // Statutory trainings (former licences) are legally enforced regardless
        // of employer — always required.
        let statutory = req.trainings.filter(\.isStatutory)
        guard statutory.isSubset(of: held) else { return false }
        // Safety-critical / regulated fields (health, transportation, law, …)
        // also gate on their non-statutory trainings (former certifications) —
        // you can't practise without the credential.
        if category.requiresCredentials {
            let preference = req.trainings.filter { !$0.isStatutory }
            return preference.isSubset(of: held)
        }
        // Everywhere else there's no hard-skill gate — hiring turns on the
        // soft-skill fit, experience, network, and fame terms in `hireProbability`.
        return true
    }

    /// Whether a degree is a *hard* hiring gate for this role. True only in
    /// regulated professions (`category.educationIsMandatory`); everywhere else a
    /// degree is optional and merely lifts the odds (see `educationFitTerm`).
    var educationIsMandatory: Bool { category.educationIsMandatory }

    /// The education gate for hiring: enforced only where a degree is mandatory.
    /// Elsewhere it's always "met" so a lack of degree never blocks the
    /// application — it just costs hire probability.
    func educationGateMet(for player: Player) -> Bool {
        guard educationIsMandatory else { return true }
        return educationMet(for: player)
    }

    /// Age gate for unskilled roles. Jobs that demand no formal education
    /// (`requirements.education.minEQF == 0`) still require the player to be
    /// of legal working age (`GameConstants.minimumWorkingAge`). Roles that
    /// require a degree clear this gate implicitly via years in school.
    func ageGateMet(for player: Player) -> Bool {
        guard requirements.education.minEQF == 0 else { return true }
        return player.age >= GameConstants.minimumWorkingAge
    }

    func allRequirementsMet(for player: Player) -> Bool {
        // Simplified mode hires on the degree (where mandatory) plus years in the
        // field alone — no hard-skill gate.
        if player.isSimplified {
            return ageGateMet(for: player) && educationGateMet(for: player) && experienceMet(for: player)
        }
        // Hard gates: minimum working age (for unskilled roles), degree (only in
        // regulated fields), hard skills (licences/certs/portfolio per field &
        // employer), and a baseline of experience (`minYearsExperience`). Beyond
        // that baseline, additional years further lift the hire probability
        // (see `experienceFitTerm`); a non-mandatory degree and soft skills are
        // helpful only.
        return ageGateMet(for: player) && educationGateMet(for: player) && hardSkillsMet(for: player) && experienceMet(for: player)
    }

    /// Additive hire-probability adjustment from formal education when the degree
    /// is *not* a hard gate. Meeting (or exceeding) the role's expected level is
    /// neutral — the upside of a strong degree comes from `relevantPrestigeBonus`.
    /// Falling short penalises, −0.10 per education level below the expectation
    /// (capped at −0.30), so a relevant degree still meaningfully helps even
    /// where it isn't strictly required.
    func educationFitTerm(for player: Player) -> Double {
        guard !educationIsMandatory else { return 0.0 }
        let required = requirements.education.minEQF
        guard required > 0 else { return 0.0 }
        let playerEQF = player.degrees.last?.eqf ?? 0
        guard playerEQF < required else { return 0.0 }
        return max(-0.30, Double(required - playerEQF) * -0.10)
    }

    func salaryAlignmentFactor(requestedSalary: Double) -> Double {
        let ratio = requestedSalary / Double(annualIncome)
        if ratio <= 1.0 { return 1.0 }
        // Asking more than budget: probability drops steeply above 33% excess.
        return max(0.0, 1.0 - (ratio - 1.0) * 3.0)
    }

    func hireProbability(for player: Player, requestedSalary: Double) -> Double {
        // Founders aren't "hired" — their odds come from capital + founder grit.
        // Preview the odds as if the target capital were fully funded.
        if isEntrepreneurial {
            return founderSuccessProbability(for: player, investedCapital: targetCapital ?? 0)
        }
        guard allRequirementsMet(for: player) else { return 0.0 }
        // Breakthrough gate: a career like Professional Player is effectively
        // closed without its signature fame award (a junior-competition win) —
        // odds sit at the floor no matter how skilled the applicant, in every
        // mode. Holding it opens the door (and adds a dominant bonus below).
        let hasBreakthrough: Bool
        if let key = breakthroughFame {
            hasBreakthrough = player.fameAwards.contains { $0.title == key }
            if !hasBreakthrough { return 0.05 }
        } else {
            hasBreakthrough = false
        }
        // Simplified mode: meeting the gate (degree + experience) is a sure hire.
        // No skill score, prestige, tier, or salary-fit adjustments.
        if player.isSimplified { return 1.0 }
        // Unregulated fields never *hard-gate* a role on a degree or credential —
        // you can always apply. But a skilled role still needs some qualification
        // behind it: with no post-secondary education, no field-relevant
        // credential, and no prior experience in the field, an applicant has
        // nothing to show and their odds sit at the floor. Unskilled roles need
        // nothing; regulated fields gate on their mandated degree/licence instead.
        if !educationIsMandatory && !category.requiresCredentials && !isLowSkilled {
            let hasEducation = player.degrees.contains { $0.eqf >= GameConstants.promotionMinEQF }
            let hasCredential = player.trainingCareerBonus(for: category) > 0
            let hasExperience = relevantYears(for: player) > 0
            if !hasEducation && !hasCredential && !hasExperience { return 0.05 }
        }
        let skillScore = Double(softSkillsHelpfulScore(for: player)) / Double(Self.scoredSoftSkills.count)
        let prestige = relevantPrestigeBonus(for: player)
        // Where a degree isn't mandatory, falling short of the expected level
        // still costs probability (a relevant degree helps you stand out).
        let education = educationFitTerm(for: player)
        // A professional network in this field — built by attending its summits
        // and conferences — tilts the odds in the applicant's favour.
        let network = player.networkBonus(for: category)
        // Experience the employer expects: a shortfall drags the
        // odds down, a seasoned applicant nudges them up.
        let experience = experienceFitTerm(for: player)
        // Industry-scoped fame opens doors — and a body of accomplished projects
        // (the main fame source) is a significant lift for roles in that same
        // field: a strong portfolio nearly rivals the soft-skill fit term, but
        // helps only its own field (see fameHireBonus). Top leadership roles
        // weight reputation even more heavily.
        let fame = player.fameHireBonus(for: category, topPosition: isTopLeadership)
        // The breakthrough fame award (held — we returned at the floor above if
        // not) is the dominant hiring factor for gated careers.
        let breakthrough = hasBreakthrough ? Self.breakthroughBonus : 0.0
        // A relevant skill-building credential (coding/game-dev/design/performing
        // program) demonstrably helps you land a role in its field.
        let credential = player.trainingCareerBonus(for: category)
        let raw = (0.2 + skillScore * 0.7 + prestige + education + player.difficulty.opportunityBonus + network + experience + fame + breakthrough + credential)
            * salaryAlignmentFactor(requestedSalary: requestedSalary)
        return max(0.05, min(0.95, raw))
    }

    // MARK: - Entrepreneurial path

    /// True for founder roles, which are gated on capital + grit rather than
    /// credentials. Identified by carrying a `targetCapital` (rather than by
    /// category) so founder roles can live under the Business category.
    var isEntrepreneurial: Bool { targetCapital != nil }

    /// True for a senior seat where equity/strategy plays make sense — the roles
    /// that unlock the Boardroom (`ExecutiveDecision`). Covers every founder
    /// venture plus the top leadership rung of a business-style track (C-suite,
    /// director, partner in Business/Entrepreneurship/Finance/Technology). A
    /// Head Chef or Charge Nurse tops out their ladder too, but doesn't run a
    /// cap table — so `isTopLeadership` alone isn't enough.
    var isExecutive: Bool {
        if isEntrepreneurial { return true }
        guard isTopLeadership else { return false }
        switch category {
        case .business, .entrepreneurship, .finance, .technology:
            return true
        default:
            return false
        }
    }

    /// Whether this is unskilled work — a role requiring no post-secondary
    /// education or training (below `GameConstants.promotionMinEQF`). Such jobs
    /// don't hand out in-place promotions (see `Player.promotionChance`); the
    /// player climbs out of them by applying to a higher role instead.
    var isLowSkilled: Bool { requirements.education.minEQF < GameConstants.promotionMinEQF }

    /// Probability that a founding attempt succeeds. Driven by *who the founder
    /// is*, not their bank balance: experience in the venture's own industry and
    /// how well their soft skills fit what the business demands are the two big
    /// levers, with the size of the stake a supporting factor. The industry
    /// experience baseline (`minYearsExperience`) is still a hard gate — you
    /// can't credibly launch a restaurant having never worked in hospitality.
    func founderSuccessProbability(for player: Player, investedCapital: Int) -> Double {
        guard isEntrepreneurial, let target = targetCapital, target > 0 else { return 0.0 }
        guard experienceMet(for: player) else { return 0.0 }
        let experience = founderExperienceFit(for: player) * 0.40   // up to +40%
        let skill = founderSkillFit(for: player) * 0.35             // up to +35%
        let capitalRatio = Double(investedCapital) / Double(target)
        let capital = min(capitalRatio, 1.0) * 0.15                 // up to +15%
        // A relevant skill-building credential (e.g. a Coding Bootcamp for a SaaS
        // startup, a Game Dev Program for an indie studio) lifts a founder's odds.
        let credential = player.trainingCareerBonus(for: category) // up to +15%
        return max(0.03, min(0.95, 0.05 + experience + skill + capital + credential))
    }

    /// 0...1 measure of how seasoned the player is in this venture's industry.
    /// Relevant industry years (see `relevantYears`) scaled against an ideal set
    /// a little above the entry gate, so clearing the minimum is a decent start
    /// and a veteran of the field maxes it out.
    func founderExperienceFit(for player: Player) -> Double {
        let ideal = max(expectedYearsExperience + 4, 6)
        return min(Double(relevantYears(for: player)) / Double(ideal), 1.0)
    }

    /// 0...1 fit of the player's soft skills for founding *this* venture. Blends
    /// how well they match the business's own skill profile (its
    /// `requirements.softSkills`) with raw entrepreneurial grit — the
    /// Risk-Taker / Visionary / Persuader traits every founder leans on
    /// regardless of field. The field-specific profile is weighted a little more.
    func founderSkillFit(for player: Player) -> Double {
        let p = player.softSkills
        let req = requirements.softSkills

        let profileAxes = Job.scoredSoftSkills.filter { req[keyPath: $0] > 0 }
        let profileFit: Double = profileAxes.isEmpty ? 0.5 : profileAxes.reduce(0.0) { acc, kp in
            acc + min(Double(p[keyPath: kp]) / Double(req[keyPath: kp]), 1.0)
        } / Double(profileAxes.count)

        let gritKeys: [WritableKeyPath<SoftSkills, Int>] = [
            \.riskTakingAndInitiative, \.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
        ]
        let grit = gritKeys.reduce(0.0) { acc, kp in
            acc + min(Double(p[keyPath: kp]) / 6.0, 1.0)
        } / Double(gritKeys.count)

        return profileFit * 0.6 + grit * 0.4
    }

    /// Hire-probability bonus from the player's most prestigious *relevant* degree.
    /// Prefers degrees in the job's accepted profiles when such a list is set.
    func relevantPrestigeBonus(for player: Player) -> Double {
        let eligible = player.degrees.filter { $0.eqf >= requirements.education.minEQF }
        guard !eligible.isEmpty else { return 0.0 }

        let matching: [Education]
        if let accepted = requirements.education.acceptedProfiles, !accepted.isEmpty {
            matching = eligible.filter { degree in
                guard let p = degree.profile else { return false }
                return accepted.contains(p)
            }
        } else {
            matching = eligible
        }
        let pool = matching.isEmpty ? eligible : matching
        let bestPrestige = pool.map { $0.tier.prestige }.max() ?? 0
        switch bestPrestige {
        case 3:  return 0.10  // Elite
        case 2:  return 0.05  // State
        default: return 0.0   // Community / unranked
        }
    }

    /// Identifies this role for tracking one application per year.
    var applicationKey: String { id }

    /// The job priced at its published median, with no random variance. Used by
    /// the listing/detail screens so salaries are deterministic and comparable.
    func atBaseSalary() -> Job {
        var copy = self
        copy.annualIncome = income
        return copy
    }
}

// MARK: - Seniority helpers

extension Job {
    /// Title prefixes that mark a seniority variant of a base role. Used to
    /// group seniority ladders under a single base title and to label the
    /// rung within that ladder. Order matters only for display.
    static let seniorityPrefixes: [String] = [
        "Apprentice ", "Junior ", "Mid-Level ", "Senior ", "Lead ",
        "Principal ", "Staff ", "Head ", "Sous ",
        "Executive ", "Master ", "Charge ",
        "Amateur ", "Professional ", "Elite "
    ]

    /// Strips a recognised seniority prefix from `id`, returning the base role
    /// title. Jobs with no recognised prefix are their own base title.
    static func baseTitle(of id: String) -> String {
        for p in seniorityPrefixes where id.hasPrefix(p) {
            return String(id.dropFirst(p.count))
        }
        return id
    }

    var baseTitle: String { Job.baseTitle(of: id) }

    /// The seniority prefix stripped from `id` (without the trailing space),
    /// or `nil` for a job whose title has no recognised prefix.
    var seniorityPrefix: String? {
        for p in Job.seniorityPrefixes where id.hasPrefix(p) {
            return String(p.dropLast())
        }
        return nil
    }

    /// Player-facing label for this seniority level. Falls back to "Standard"
    /// when the job title carries no seniority prefix.
    var seniorityLabel: String {
        seniorityPrefix ?? "Standard"
    }

    /// Ordered rank of this rung within its ladder, used to promote to the next
    /// level up (same `baseTitle`). The bare base title (no prefix) sits
    /// mid-ladder, between Junior and Senior; prefixes marking the same tier
    /// share a rank so a ladder climbs one recognised step at a time.
    var seniorityRank: Int {
        switch seniorityPrefix {
        case "Apprentice", "Amateur":                      return 0
        case "Junior":                                     return 1
        case "Mid-Level", .none:                           return 2
        case "Senior", "Sous", "Professional":             return 3
        case "Lead", "Head", "Charge", "Elite":            return 4
        case "Principal", "Staff", "Executive", "Master":  return 5
        default:                                           return 2
        }
    }

    /// Player-facing occupation title. Founding a venture makes the player its
    /// CEO, so an entrepreneurial occupation reads "CEO, <Venture>" rather than
    /// the bare venture name (`baseTitle` stays the venture for experience and
    /// catalogue lookups).
    var displayTitle: String {
        isEntrepreneurial ? "CEO, \(id)" : id
    }

    /// Apex seniority prefixes that represent the top rung of a career ladder.
    private static let leadershipPrefixes: Set<String> = [
        "Lead", "Principal", "Staff", "Head", "Executive", "Master", "Charge", "Chief"
    ]

    /// Title keywords that mark a top leadership role even without a seniority
    /// prefix (e.g. "Marketing Director", "Managing Partner", chiefs). Tracks that
    /// top out with a `Lead`/`Head`/`Principal` prefix instead are covered by
    /// `leadershipPrefixes`; this list catches the keyword-only apexes.
    private static let leadershipKeywords: [String] = [
        "Director", "Partner", "Chief"
    ]

    /// Track apexes listed explicitly because their titles carry no leadership
    /// prefix/keyword — and to avoid sweeping in their mid-level rungs (e.g.
    /// Hotel/Sales/Project Manager, or Startup Founder below Serial Entrepreneur).
    private static let capstoneTitles: Set<String> = [
        "Store Manager", "Operations Manager", "Farm Manager", "Serial Entrepreneur"
    ]

    /// True for the top management role of a career track — the win condition
    /// ("Make it to the top") for the simplified game mode. Covers apex seniority
    /// rungs, chief/director titles, and the explicit manager capstones.
    var isTopLeadership: Bool {
        if let prefix = seniorityPrefix, Job.leadershipPrefixes.contains(prefix) {
            return true
        }
        if Job.capstoneTitles.contains(id) {
            return true
        }
        return Job.leadershipKeywords.contains { id.contains($0) }
    }
}

// Example remains only for previews if needed
var jobExample = Job(
    id: "superman",
    category: .agriculture,
    income: 10000,
    summary: "sdf",
    icon: "🦸",
    requirements: Job.Requirements(
        education: .init(minEQF: 5, acceptedProfiles: nil),
        softSkills: .init(
            analyticalReasoningAndProblemSolving: 2,
            creativityAndInsightfulThinking: 3,
            communicationAndNetworking: 4,
            leadershipAndInfluence: 2,
            visionaryThinkingAndAmbition: 1,
            carefulnessAndAttentionToDetail: 1,
            tinkeringAndFingerPrecision: 1,
            spacialNavigationAndOrientation: 1,
            resilienceAndEndurance: 1,
            stressResistanceAndEmotionalRegulation: 0,
            outdoorAndWeatherResilience: 0,
            collaborationAndTeamwork: 0,
            timeManagementAndPlanning: 0,
            selfDisciplineAndPerseverance: 0,
            presentationAndStorytelling: 0
        ),
        hardSkills: .init(trainings: [])
    ),
)

