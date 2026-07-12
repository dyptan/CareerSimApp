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
        // Industry-scoped fame opens doors: a noticed body of side work (and,
        // in Show Business, competition/side-hustle trophies) lifts the odds for
        // roles in that same field — but only that field (see fameHireBonus).
        // Top leadership roles weight reputation far more heavily.
        let fame = player.fameHireBonus(for: category, topPosition: isTopLeadership)
        // The breakthrough fame award (held — we returned at the floor above if
        // not) is the dominant hiring factor for gated careers.
        let breakthrough = hasBreakthrough ? Self.breakthroughBonus : 0.0
        let raw = (0.2 + skillScore * 0.7 + prestige + education + player.difficulty.opportunityBonus + network + experience + fame + breakthrough)
            * salaryAlignmentFactor(requestedSalary: requestedSalary)
        return max(0.05, min(0.95, raw))
    }

    // MARK: - Entrepreneurial path

    /// True for founder roles, which are gated on capital + grit rather than
    /// credentials. Identified by carrying a `targetCapital` (rather than by
    /// category) so founder roles can live under the Business category.
    var isEntrepreneurial: Bool { targetCapital != nil }

    /// Whether this is unskilled work — a role requiring no post-secondary
    /// education or training (below `GameConstants.promotionMinEQF`). Such jobs
    /// don't hand out in-place promotions (see `Player.promotionChance`); the
    /// player climbs out of them by applying to a higher role instead.
    var isLowSkilled: Bool { requirements.education.minEQF < GameConstants.promotionMinEQF }

    /// Probability that a founding attempt succeeds. Driven mainly by how well
    /// the invested capital covers the venture's target, with a smaller bump
    /// from the founder skill set (Risk-Taker / Visionary / Persuader). The
    /// experience gate still applies — you can't skip rungs of the ladder.
    func founderSuccessProbability(for player: Player, investedCapital: Int) -> Double {
        guard isEntrepreneurial, let target = targetCapital, target > 0 else { return 0.0 }
        guard experienceMet(for: player) else { return 0.0 }
        let capitalRatio = Double(investedCapital) / Double(target)
        let capitalTerm = min(capitalRatio, 1.0) * 0.55          // up to +55% at full funding
        let overfundBonus = min(max(capitalRatio - 1.0, 0.0), 1.0) * 0.10  // a little more for a fat war chest
        let skillTerm = founderSkillFit(for: player) * 0.30      // up to +30%
        return max(0.03, min(0.92, 0.03 + capitalTerm + overfundBonus + skillTerm))
    }

    /// 0...1 fit of the player against this venture's founder skills.
    func founderSkillFit(for player: Player) -> Double {
        let keys: [WritableKeyPath<SoftSkills, Int>] = [
            \.riskTakingAndInitiative, \.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
        ]
        let req = requirements.softSkills
        let p = player.softSkills
        let total = keys.reduce(0.0) { acc, kp in
            let need = max(req[keyPath: kp], 1)
            return acc + min(Double(p[keyPath: kp]) / Double(need), 1.0)
        }
        return total / Double(keys.count)
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

/// Realistic-mode founder loop: once a player launches an entrepreneurial Job
/// the game tracks an `ActiveStartup` (see `Player.activeStartup`), and each
/// year `advanceYear` consults this enum to roll a buyout offer or determine
/// the fire-sale value during a recession.
///
/// The four rungs mirror the founder titles declared in `JobCatalog.allJobs`
/// (Side Hustler → Small Business Owner → Startup Founder → Serial Entrepreneur).
/// Holding a successful offer advances `rungIndex`; selling banks the offer
/// and ends the venture.
enum FounderLadder {
    /// The four founder titles in climb order, matched to the ids registered
    /// in `JobCatalog`. The index of a title is the `ActiveStartup.rungIndex`.
    static let rungTitles: [String] = [
        "Side Hustler", "Small Business Owner", "Startup Founder", "Serial Entrepreneur"
    ]

    /// Per-rung buyout multiplier on the rung's `targetCapital`. A Side Hustler
    /// acquihire is small money; an exit at the Serial Entrepreneur tier is
    /// life-changing. Tuned so each rung's offer comfortably exceeds the
    /// previous one's, rewarding the Hold-and-grow path.
    private static let exitMultiplier: [Double] = [2.0, 3.0, 6.0, 12.0]

    /// Per-rung base probability that an annual roll lands a buyout offer.
    /// Smaller ventures sell more often; world-changing companies take patience.
    /// The founder's skill fit adds up to +0.20 on top.
    private static let baseOfferChance: [Double] = [0.35, 0.25, 0.18, 0.12]

    /// Fraction of the (jittered) offer paid out during a forced bankruptcy.
    /// A fire-sale during a recession returns a fraction of the would-be exit,
    /// less than the half-stake salvage on a regular failure but still
    /// meaningful — the player walks away with *something*.
    static let bankruptcySalvageFraction: Double = 0.30

    /// Number of rungs (the top index is `count - 1`).
    static var count: Int { rungTitles.count }

    /// Index of the founder rung carrying this title, or `nil` for non-founder
    /// titles. Matches against `Job.baseTitle` so seniority variants resolve.
    static func rungIndex(forTitle title: String) -> Int? {
        rungTitles.firstIndex(of: Job.baseTitle(of: title))
    }

    /// Resolves the Job description for a rung by looking it up in the
    /// shared catalogue. Returns nil if the catalogue is missing the title
    /// (shouldn't happen — guards against typos / future renames).
    static func job(at rungIndex: Int, in catalogue: [Job]) -> Job? {
        guard rungTitles.indices.contains(rungIndex) else { return nil }
        let title = rungTitles[rungIndex]
        return catalogue.first { $0.id == title }
    }

    /// Headline buyout value for a rung — the rung's `targetCapital` scaled by
    /// the tier's exit multiplier. The actual offer the player sees is this
    /// value jittered ±25% by `randomOffer(forRungIndex:)`.
    static func headlineOffer(forRungIndex idx: Int, targetCapital: Int) -> Int {
        guard exitMultiplier.indices.contains(idx) else { return targetCapital }
        return Int((Double(targetCapital) * exitMultiplier[idx]).rounded())
    }

    /// One year's randomised buyout offer: the rung's headline value jittered
    /// uniformly within ±25%. Re-rolled every successful annual offer roll.
    static func randomOffer(forRungIndex idx: Int, targetCapital: Int) -> Int {
        let headline = headlineOffer(forRungIndex: idx, targetCapital: targetCapital)
        let jitter = Double.random(in: 0.75...1.25)
        return Int((Double(headline) * jitter).rounded())
    }

    /// Probability (clamped 0.05...0.92) that this year's annual roll surfaces
    /// a buyout offer. Built from the rung's base chance plus up to +0.20 from
    /// the player's founder-trait fit (Risk-Taker / Visionary / Persuader).
    static func offerProbability(forRungIndex idx: Int, founderSkillFit: Double) -> Double {
        guard baseOfferChance.indices.contains(idx) else { return 0 }
        let raw = baseOfferChance[idx] + min(max(founderSkillFit, 0), 1) * 0.20
        return max(0.05, min(0.92, raw))
    }

    /// Fire-sale payout when a recession forces the player to liquidate. Caps
    /// the loss while still hurting — a haircut on the rung's would-be offer.
    static func bankruptcyPayout(forRungIndex idx: Int, targetCapital: Int) -> Int {
        let headline = headlineOffer(forRungIndex: idx, targetCapital: targetCapital)
        return Int((Double(headline) * bankruptcySalvageFraction).rounded())
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

