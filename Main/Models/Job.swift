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
    /// The role this job is a rung of, irrespective of seniority — the career
    /// ladder it belongs to (see `JobCatalog.LadderSpec`). Stored, not parsed
    /// from the title: two rungs share a ladder because they were declared
    /// together, not because their titles happen to share a suffix. A role with
    /// no ladder is its own base title.
    let baseTitle: String
    /// Position within that ladder, entry rung first. Promotion moves to
    /// `rung + 1`, so two rungs can never tie for "next" the way parsed
    /// seniority prefixes could.
    let rung: Int
    /// Seniority label for this rung — "Senior", "Lead" — or empty for the rung
    /// that carries the bare role name and for roles with no ladder.
    let rungLabel: String
    /// Where the work actually happens (see `WorkSetting`). Stated in the
    /// catalogue, so the jobs list can filter on it.
    let workSetting: WorkSetting
    /// The sector the employer trades in — what the business sells, as opposed
    /// to `category`, which is what the worker does. This is the axis the
    /// economy runs on (see `Industry` and `Player.industryTrend`): a designer at
    /// a carmaker rides the automotive cycle, one at an agency rides advertising.
    let industry: Industry

    init(id: String, category: JobCategory, income: Int, summary: String, icon: String,
         requirements: Requirements, targetCapital: Int? = nil,
         baseTitle: String? = nil, rung: Int = 0, rungLabel: String = "",
         workSetting: WorkSetting = .office,
         industry: Industry = .professionalServices) {
        self.id = id
        self.category = category
        self.income = income
        self.summary = summary
        self.icon = icon
        self.requirements = requirements
        self.targetCapital = targetCapital
        self.baseTitle = baseTitle ?? id
        self.rung = rung
        self.rungLabel = rungLabel
        self.workSetting = workSetting
        self.industry = industry
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
        // Sports: the pro-athlete track opens on a junior-competition win.
        "Player": "Junior Champion",
        // Show business: the A-list acting and music tracks each open on a rare
        // "big break" project (see the breakout ventures in `SideHustle`).
        "Movie Star": "Breakout Role",
        "Pop Star": "Hit Record",
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
        let playerEQF = player.highestEQF
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
        if isLadderVariant {
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
    /// `experienceFactor` rewards extra years probabilistically.
    func experienceMet(for player: Player) -> Bool {
        let required = requirements.minYearsExperience
        guard required > 0 else { return true }
        return relevantYears(for: player) >= required
    }

    func hardSkillsMet(for player: Player) -> Bool {
        let req = requirements.hardSkills
        let held = player.hardSkills.trainings
        // Statutory trainings are legally enforced regardless
        // of employer — always required.
        let statutory = req.trainings.filter(\.isStatutory)
        guard statutory.isSubset(of: held) else { return false }
        // Safety-critical / regulated fields (health, transportation, law, …)
        // also gate on their non-statutory trainings —
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
    /// degree is optional and merely lifts the odds (see `educationFactor`).
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

    /// The player's best formal qualification, in EQF levels. Uses the highest
    /// degree held rather than the most recent one, so taking a vocational
    /// course after a degree doesn't read as a downgrade.
    func playerEducationLevel(for player: Player) -> Int {
        player.highestEQF
    }

    /// How many EQF levels the player is short of what this role expects.
    /// Zero once they meet or exceed the bar.
    func educationShortfall(for player: Player) -> Int {
        max(0, requirements.education.minEQF - playerEducationLevel(for: player))
    }

    /// Whether the player holds a qualification at or above the role's expected
    /// level *in a field the role accepts*. Roles below degree level list no
    /// accepted fields, so any qualification counts there.
    ///
    /// One definition, read by the hiring factor and the promotion term alike,
    /// so "the right degree" can't come to mean two different things.
    func hasAcceptedDegree(for player: Player) -> Bool {
        let required = requirements.education.minEQF
        let qualifying = player.degrees.filter { $0.eqf >= required }
        guard !qualifying.isEmpty else { return false }
        guard let accepted = requirements.education.acceptedProfiles, !accepted.isEmpty else {
            return true
        }
        return qualifying.contains { degree in
            guard let profile = degree.profile else { return false }
            return accepted.contains(profile)
        }
    }

    /// Every hard requirement expressed as a factor on the hire odds.
    ///
    /// A requirement that is genuinely absolute — a statutory licence, a degree
    /// in a regulated profession, no relevant experience whatsoever —
    /// contributes **zero**, and zero times anything is zero. That is what makes
    /// it absolute, so there is no separate boolean gate that something else has
    /// to agree with. Everything else grades.
    struct RequirementFit {
        let age: Double
        let education: Double
        let credentials: Double
        let experience: Double

        /// The combined multiplier applied to the soft-skill score.
        var factor: Double { age * education * credentials * experience }
        /// Nothing can overcome a zero — the role is closed to this player today.
        var isBlocked: Bool { factor == 0 }
    }

    /// How well the player satisfies this role's requirements, as factors.
    func requirementFit(for player: Player) -> RequirementFit {
        RequirementFit(
            age: ageGateMet(for: player) ? 1.0 : 0.0,
            education: educationFactor(for: player),
            // Simplified mode hires on degree + experience alone — no licence gate.
            credentials: (player.isSimplified || hardSkillsMet(for: player)) ? 1.0 : 0.0,
            experience: experienceFactor(for: player)
        )
    }

    /// True when no requirement is a hard blocker. Derived from
    /// `requirementFit` so the gate and the odds can never disagree.
    func allRequirementsMet(for player: Player) -> Bool {
        !requirementFit(for: player).isBlocked
    }

    /// Education as a multiplier. In the regulated professions the degree is
    /// absolute, so it is 1 or 0. Everywhere else it grades: short of the
    /// expected level costs `educationShortfallPerLevel` a level down to a
    /// floor, and clearing the bar pays — more in a field the role accepts than
    /// in an unrelated one.
    func educationFactor(for player: Player) -> Double {
        if educationIsMandatory || player.isSimplified {
            return educationGateMet(for: player) ? 1.0 : 0.0
        }
        let required = requirements.education.minEQF
        guard required > 0 else { return 1.0 }
        let shortfall = educationShortfall(for: player)
        if shortfall > 0 {
            return max(GameConstants.educationShortfallFloor,
                       1.0 - Double(shortfall) * GameConstants.educationShortfallPerLevel)
        }
        return hasAcceptedDegree(for: player)
            ? GameConstants.relevantDegreeMultiplier
            : GameConstants.unrelatedDegreeMultiplier
    }

    /// Experience as a multiplier: pro-rata up to what the employer expects, a
    /// modest edge beyond it, and zero with no relevant years at all — you can't
    /// claim a background you don't have. Simplified mode keeps the old
    /// all-or-nothing answer, so a young player sees "you qualify" or not.
    func experienceFactor(for player: Player) -> Double {
        let required = requirements.minYearsExperience
        guard required > 0 else { return 1.0 }
        if player.isSimplified { return experienceMet(for: player) ? 1.0 : 0.0 }
        let ratio = Double(relevantYears(for: player)) / Double(required)
        if ratio >= 1.0 {
            return min(GameConstants.experienceVeteranMultiplier,
                       1.0 + (ratio - 1.0) * GameConstants.experienceVeteranRate)
        }
        return ratio
    }

    /// Education's contribution to the annual promotion odds. Being
    /// under-credentialled for the role you hold caps how far you climb in it —
    /// the way to lift it is to go and earn the qualification.
    func educationPromotionTerm(for player: Player) -> Double {
        let required = requirements.education.minEQF
        guard required > 0 else { return 0.0 }
        let shortfall = educationShortfall(for: player)
        if shortfall > 0 {
            return max(GameConstants.promotionEducationFloor,
                       Double(shortfall) * GameConstants.promotionEducationPerLevel)
        }
        return hasAcceptedDegree(for: player) ? GameConstants.promotionRelevantDegreeBonus : 0.0
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
        // One formula: the hard requirements are factors, not a separate gate.
        // A zero among them closes the role outright.
        let fit = requirementFit(for: player)
        guard !fit.isBlocked else { return 0.0 }
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
        // A relevant skill-building credential (coding/game-dev/design/performing
        // program) demonstrably helps you land a role in its field.
        //
        // The old "nothing to show" special case lived here — a hardcoded 0.05
        // for an applicant with no degree, credential or experience. The
        // requirement factors express that by composition now: missing education
        // multiplies down to its floor, and the absence of a credential or
        // experience simply earns nothing.
        let credential = player.trainingCareerBonus(for: category)
        let skillScore = Double(softSkillsHelpfulScore(for: player)) / Double(Self.scoredSoftSkills.count)
        let prestige = relevantPrestigeBonus(for: player)
        // A professional network in this field — built by attending its summits
        // and conferences — tilts the odds in the applicant's favour.
        let network = player.networkBonus(for: category)
        // Industry-scoped fame opens doors — and a body of accomplished projects
        // (the main fame source) is a significant lift for roles in that same
        // field: a strong portfolio nearly rivals the soft-skill fit term, but
        // helps only its own field (see fameHireBonus). Top leadership roles
        // weight reputation even more heavily.
        let fame = player.fameHireBonus(for: category, topPosition: isTopLeadership)
        // The breakthrough fame award (held — we returned at the floor above if
        // not) is the dominant hiring factor for gated careers.
        let breakthrough = hasBreakthrough ? Self.breakthroughBonus : 0.0
        // What the applicant brings, before the requirements are applied.
        let merit = 0.2 + skillScore * 0.7 + prestige + player.difficulty.opportunityBonus
            + network + fame + breakthrough + credential
        let raw = merit * fit.factor * salaryAlignmentFactor(requestedSalary: requestedSalary)
        // What this industry is doing this year. A booming field hires people it
        // would pass over in a slump, and the same application is a materially
        // different bet depending on when it lands (see `IndustryClimate`).
        let climate = player.climate(for: industry).hireFactor
        // C-suite scarcity: executive seats are few, so even a strong candidate
        // faces long odds of landing one — most qualified applicants never make it
        // to the top. Founders make their own seat, so they're exempt.
        let scarcity = (isExecutive && !isEntrepreneurial) ? GameConstants.executiveSeatChance : 1.0
        return max(0.05, min(0.95, raw * climate * scarcity))
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
        case .business, .entrepreneurship, .technology:
            return true
        default:
            return false
        }
    }

    /// Whether pay for this role is something the player argues for, rather than
    /// a posted rate they take or leave.
    ///
    /// Negotiation belongs to trained office work: a rate is quoted for a welder,
    /// a waiter or a receptionist, but a consultant, an engineer, a designer or
    /// an animator puts a number on the table. The bar is the role's own
    /// education expectation, so a ladder splits the way a real one does — a
    /// junior paralegal takes the posted band, the senior seat above them
    /// negotiates.
    ///
    /// `publicPayScaleTitles` is the exception the bar can't express: a role can
    /// be as trained and as office-bound as you like and still have its pay set
    /// by statute rather than by an offer.
    var salaryIsNegotiable: Bool {
        guard !isEntrepreneurial else { return false }
        guard workSetting == .office else { return false }
        guard !Job.publicPayScaleTitles.contains(baseTitle) else { return false }
        return requirements.education.minEQF >= GameConstants.negotiableSalaryMinEQF
    }

    /// Roles whose pay is a published government scale, not an offer — no
    /// candidate argues their way onto a different step of it. Keyed by
    /// `baseTitle`, so one entry covers every rung of a ladder.
    static let publicPayScaleTitles: Set<String> = [
        "Air Traffic Controller",
        "Judge",
    ]

    /// Whether this is unskilled work — a role requiring no post-secondary
    /// education or training (below `GameConstants.promotionMinEQF`). Such jobs
    /// don't hand out in-place promotions (see `Player.promotionChance`); the
    /// player climbs out of them by applying to a higher role instead.
    /// Founder ventures are exempt: they carry `minEQF: 0` because founders
    /// aren't gated on degrees, not because the work is unskilled — a growing
    /// business raises its owner's pay (the in-place merit-raise branch).
    var isLowSkilled: Bool {
        !isEntrepreneurial && requirements.education.minEQF < GameConstants.promotionMinEQF
    }

    /// Probability that a founding attempt succeeds. Driven by *who the founder
    /// is*, not their bank balance: experience in the venture's own industry and
    /// how well their soft skills fit what the business demands are the two big
    /// levers, with the size of the stake a supporting factor.
    ///
    /// **Capital is the only hard requirement.** Anyone with a stake may try
    /// anything — nobody is barred from opening a restaurant for never having
    /// worked in hospitality, they are simply very likely to fail at it. The
    /// industry-experience baseline that used to gate this outright is now just
    /// the largest probabilistic term (`founderExperienceFit`), so an unprepared
    /// founder sits near the 0.03 floor rather than being refused.
    func founderSuccessProbability(for player: Player, investedCapital: Int) -> Double {
        guard isEntrepreneurial, let target = targetCapital, target > 0 else { return 0.0 }
        // The one hard requirement. Everything else below only moves the odds.
        guard investedCapital > 0 else { return 0.0 }
        // Weighted so that even a maxed-out founder lands around the
        // `founderMaxSuccess` ceiling — founding is a gamble, not a formality —
        // while weaker preparation falls away steeply below it.
        let experience = founderExperienceFit(for: player) * 0.26   // up to +26%
        let skill = founderSkillFit(for: player) * 0.20             // up to +20%
        let capitalRatio = Double(investedCapital) / Double(target)
        let capital = min(capitalRatio, 1.0) * 0.09                 // up to +9%
        // A relevant skill-building credential (e.g. a Coding Bootcamp for a SaaS
        // startup, a Game Dev Program for an indie studio) lifts a founder's odds.
        let credential = player.trainingCareerBonus(for: category) // up to +15%
        // Founding into a contracting market is the harder version of the same
        // bet — customers and backers are scarcer in a slump.
        let climate = player.climate(for: industry).hireFactor
        let raw = (0.05 + experience + skill + capital + credential) * climate
        return max(0.03, min(GameConstants.founderMaxSuccess, raw))
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
    /// Whether this job is a rung of a multi-step ladder rather than a
    /// standalone role — i.e. it carries a seniority label.
    var isLadderVariant: Bool { !rungLabel.isEmpty }

    /// Player-facing label for this seniority level. "Standard" for the rung
    /// that carries the bare role name.
    var seniorityLabel: String {
        rungLabel.isEmpty ? "Standard" : rungLabel
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
        if Job.leadershipPrefixes.contains(rungLabel) {
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

