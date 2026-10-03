import Foundation


struct Job: Identifiable, Codable, Hashable {
    let id: String
    let category: JobCategory
    let income: Int            // base/reference salary shown in job listings, in local money
    /// The catalogue's US-dollar median for the role (`income` before
    /// `Country.localPay`). Rules about the *role* — which ones prefer a
    /// degree — read this, so they don't shift with a country's pay levels.
    let referenceIncome: Int
    let summary: String
    let icon: String
    let requirements: Requirements
    var annualIncome: Int      // actual pay locked in when the job was taken
    /// For entrepreneurial roles: the capital a founder ideally puts up to launch
    /// this venture. Feeds the founder's preparation (see `founderSuccessProbability`).
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
    var industry: Industry

    init(id: String, category: JobCategory, income: Int, summary: String, icon: String,
         requirements: Requirements, targetCapital: Int? = nil, referenceIncome: Int? = nil,
         baseTitle: String? = nil, rung: Int = 0, rungLabel: String = "",
         workSetting: WorkSetting = .office,
         industry: Industry = .professionalServices) {
        self.id = id
        self.category = category
        self.income = income
        self.referenceIncome = referenceIncome ?? income
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

            /// The requirement in `country`'s school names (see `Country.educationLevelName`).
            func educationLabel(in country: Country) -> String {
                country.educationLevelName(minEQF: minEQF)
            }

            func educationLabel() -> String {
                switch minEQF {
                case ..<1: return L("Primary school")
                case 1: return L("Primary school")
                case 2: return L("Middle school")
                case 3: return L("High school")
                case 4: return L("College / Vocational")
                case 5: return L("University — Bachelor's")
                case 6: return L("University — Master's")
                case 7: return L("Doctorate")
                default: return L("Doctorate+")
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
        // Sports: the pro-athlete track opens on a junior-competition win. (The
        // screen and music big breaks open star *projects* instead — see
        // `SideHustle.requiresAward`.)
        "Player": "Junior Champion",  // i18n:ignore ids, never shown
    ]

    /// The breakthrough fame award this role requires, or nil for ordinary
    /// roles. Keyed by `baseTitle`, so every rung of a ladder shares it.
    var breakthroughFame: String? {
        Job.breakthroughFameByRole[baseTitle]
    }

    /// Hire-probability bonus once the player holds this role's breakthrough
    /// fame award. Large enough to dominate the formula — it is the single
    /// most important factor for a gated career.
    static let breakthroughBonus: Double = 0.20

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

    /// The axes this role actually asks something of — the ones its profile
    /// scores above zero. Everything else is irrelevant to the job and is
    /// neither rewarded nor penalised.
    var askedSoftSkills: [WritableKeyPath<SoftSkills, Int>] {
        Self.scoredSoftSkills.filter { requirements.softSkills[keyPath: $0] > 0 }
    }

    /// 0...1 fit of the player's soft skills against what this role asks for.
    ///
    /// Two properties matter, and the old scorer had neither.
    ///
    /// **It reads only the axes the role names.** It used to count how many of
    /// all eighteen axes the player cleared, which meant an axis a role asks
    /// nothing of scored as a pass — so a role listing five requirements handed
    /// out thirteen free points and a role listing fourteen handed out four.
    /// Listing a nice-to-have made a job measurably *harder to get*, which is
    /// backwards, and left profile length acting as a difficulty knob nobody
    /// had set deliberately: a Junior Graphic Artist was a harder hire than a
    /// Senior Accountant purely because its category's default profile was
    /// longer.
    ///
    /// **It grades.** Each axis pays out in proportion, so three of a required
    /// four is worth three quarters rather than nothing. The all-or-nothing
    /// version made the last point on an axis worth as much as the first three
    /// together, and disagreed with `founderSkillFit`, which has always graded
    /// its own profile term this way.
    ///
    /// A role that asks for nothing is a perfect fit for anyone.
    func softSkillFit(for player: Player) -> Double {
        let asked = askedSoftSkills
        guard !asked.isEmpty else { return 1.0 }
        let required = requirements.softSkills
        return asked.reduce(0.0) { acc, kp in
            acc + min(Double(player.softSkills[keyPath: kp]) / Double(required[keyPath: kp]), 1.0)
        } / Double(asked.count)
    }

    /// How many of the axes this role asks for the player fully clears. Display
    /// only — `softSkillFit` is what the odds are built from.
    func softSkillsHelpfulScore(for player: Player) -> Int {
        askedSoftSkills.reduce(0) { score, kp in
            score + (player.softSkills[keyPath: kp] >= requirements.softSkills[keyPath: kp] ? 1 : 0)
        }
    }

    /// Years of the player's experience relevant to this role. A standalone role
    /// (entry-level, or a top capstone with no junior rung) or a ladder's entry
    /// rung counts accumulated whole-industry years, crediting related
    /// industries too — notably, entrepreneurship experience counts toward
    /// Business roles (see `Player.industryExperience`).
    ///
    /// A rung above entry counts tenure on *this* ladder in full and the rest of
    /// the player's years in the field at half value (rounded down):
    /// `roleYears + (industryYears − roleYears) / 2`. Lateral moves at the same
    /// level are common in tech and business, so a data analyst's four years
    /// count for something toward mid-level software engineering — but not as
    /// much as four years on the engineering ladder itself.
    ///
    /// A role whose years can only be earned on another ladder
    /// (`JobCatalog.tenureLadderByBaseTitle` — a surgeon's years are years as a
    /// doctor) counts that ladder's tenure alone.
    func relevantYears(for player: Player) -> Int {
        if let ladder = JobCatalog.tenureLadderByBaseTitle[baseTitle] {
            return player.experienceByRole[ladder] ?? 0
        }
        let industryYears = player.industryExperience(for: category)
        guard isLadderVariant else { return industryYears }
        let roleYears = player.experienceByRole[baseTitle] ?? 0
        return roleYears + max(0, industryYears - roleYears) / 2
    }

    /// The ladder whose tenure this role's experience bar reads, when it isn't
    /// whole-category years: its own ladder for a rung above entry, or the one
    /// `JobCatalog.tenureLadderByBaseTitle` names. For "5 yr as Physician"-style
    /// labels.
    var experienceLadder: String? {
        JobCatalog.tenureLadderByBaseTitle[baseTitle] ?? (isLadderVariant ? baseTitle : nil)
    }

    /// Years of experience this role expects — its catalog baseline
    /// (`minYearsExperience`). Zero when the role has no experience baseline.
    var expectedYearsExperience: Int {
        requirements.minYearsExperience
    }

    /// Whether the player has the role's full stated experience
    /// (`minYearsExperience`). Simplified mode gates on exactly this; the
    /// realistic modes consider an applicant from `minimumQualifyingYears`
    /// (see `experienceFactor`), and a promotion into a rung requires it in
    /// full.
    func experienceMet(for player: Player) -> Bool {
        let required = requirements.minYearsExperience
        guard required > 0 else { return true }
        return relevantYears(for: player) >= required
    }

    /// Fewest relevant years at which an application is considered at all:
    /// the full figure in Simplified, otherwise the smallest whole number of
    /// years whose `experienceFactor` is above zero — `experienceStretchMin` of
    /// the stated years, or enough to reach `executiveExperienceMinFactor` on a
    /// seat-scarce role. The same arithmetic as `experienceFactor`, so the UI's
    /// "closed below N years" and the odds can't disagree.
    func minimumQualifyingYears(simplified: Bool) -> Int {
        let required = requirements.minYearsExperience
        guard required > 0 else { return 0 }
        if simplified { return required }
        return (1...required).first { years in
            experienceFactor(ratio: Double(years) / Double(required)) > 0
        } ?? required
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

    /// The realistic-mode education gate: enforced only where a degree is
    /// mandatory. Elsewhere it's always "met" so a lack of degree never blocks
    /// the application — it just costs hire probability. (Simplified mode gates
    /// every role on `educationMet`; see `educationFactor`.)
    func educationGateMet(for player: Player) -> Bool {
        guard educationIsMandatory else { return true }
        return educationMet(for: player)
    }

    /// Categories whose work falls under the FLSA's Hazardous Occupations Orders
    /// (driving, roofing, power-driven machinery, excavation), closed to minors.
    private static let hazardousCategories: Set<JobCategory> = [
        .construction, .manufacturing, .transportation,
    ]

    /// Categories whose basic roles 14–15-year-olds may legally hold: shops,
    /// food service and personal services (DOL Fact Sheet #43).
    private static let teenWorkCategories: Set<JobCategory> = [
        .retail, .hospitality, .service,
    ]

    /// The youngest a player may be hired into this role, following US
    /// child-labour law and what employers screen for:
    ///
    /// * **21** for a top leadership seat (`isTopLeadership`) — nobody runs a
    ///   shop floor, a ward or a company at 18;
    /// * **18** for the hazardous categories (construction, manufacturing,
    ///   transportation) and for any role expecting a post-secondary
    ///   qualification (EQF 4+);
    /// * **14** for basic retail, food-service and personal-service work
    ///   (EQF ≤ 2);
    /// * **16** for everything else;
    ///
    /// raised by `JobCatalog.minimumAgeByBaseTitle` where a licensing law sets a
    /// higher bar (serving alcohol, say). Founders need to be adults to stake
    /// capital (`GameConstants.minimumEntrepreneurAge`).
    ///
    /// This replaces a gate that checked age only for roles expecting no
    /// schooling at all, on the theory that school takes care of the rest —
    /// but outside the regulated fields education only grades the odds, so a
    /// 14-year-old could apply to be a software engineer and a 16-year-old
    /// cashier could become store manager.
    var minimumHireAge: Int {
        if isEntrepreneurial { return GameConstants.minimumEntrepreneurAge }
        let minEQF = requirements.education.minEQF
        let byRule: Int
        if isTopLeadership {
            byRule = GameConstants.minimumLeadershipAge
        } else if minEQF >= 4 || Job.hazardousCategories.contains(category) {
            byRule = GameConstants.adultRoleAge
        } else if minEQF <= 2 && Job.teenWorkCategories.contains(category) {
            byRule = GameConstants.minimumWorkingAge
        } else {
            byRule = GameConstants.minimumNonHazardousAge
        }
        return max(byRule, JobCatalog.minimumAgeByBaseTitle[baseTitle] ?? 0)
    }

    /// Whether the player is old enough to be hired into this role (see
    /// `minimumHireAge`).
    func ageGateMet(for player: Player) -> Bool {
        guard player.age >= minimumHireAge else { return false }
        // Professional sport signs its players young: a first pro contract
        // after the mid-twenties is vanishingly rare. A player already on the
        // ladder can still step up it.
        if baseTitle == "Player", rung >= 1, player.currentOccupation?.baseTitle != "Player",  // i18n:ignore ids, never shown
           player.age > GameConstants.latestProSigningAge {
            return false
        }
        return true
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

    /// EQF levels of a shortfall the player's *equivalent experience* makes up
    /// — at most `GameConstants.equivalentExperienceMaxCredit` (one level), and
    /// only ever toward a shortfall, never beyond the bar. Any one of these is
    /// enough, and they don't stack:
    ///
    /// * a held credential whose `careerBoost` covers this field — the
    ///   portfolio a coding bootcamp or a design program leaves you with;
    /// * `GameConstants.equivalentExperienceFame` points of fame in the field's
    ///   bucket — a body of shipped work people know;
    /// * `GameConstants.equivalentExperienceYears` years in the field.
    ///
    /// It never opens a regulated profession (there the degree is absolute; see
    /// `educationFactor`), and Simplified mode doesn't use it.
    func equivalentExperienceCredit(for player: Player) -> Int {
        let viaCredential = player.trainingCareerBonus(for: category) > 0
        let viaFame = category.fameCategory.map {
            player.famePoints(for: $0) >= GameConstants.equivalentExperienceFame
        } ?? false
        let viaYears = player.industryExperience(for: category) >= GameConstants.equivalentExperienceYears
        return (viaCredential || viaFame || viaYears) ? GameConstants.equivalentExperienceMaxCredit : 0
    }

    /// The shortfall left once equivalent experience is credited
    /// (`educationShortfall` less `equivalentExperienceCredit`, never negative).
    func creditedEducationShortfall(for player: Player) -> Int {
        let shortfall = educationShortfall(for: player)
        guard shortfall > 0 else { return 0 }
        return max(0, shortfall - equivalentExperienceCredit(for: player))
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
    /// A requirement that is genuinely absolute — being old enough, a statutory
    /// licence, a degree in a regulated profession (in Simplified, for every
    /// role), well under the expected years of experience — contributes
    /// **zero**, and zero times anything is zero. That is what makes
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

    /// Education as a multiplier.
    ///
    /// * **Simplified mode and the regulated professions:** absolute — 1 with
    ///   the expected level in a field the role accepts (`educationMet`), else
    ///   0. In Simplified this holds for *every* role, so the degree a child
    ///   picks decides which careers open to them.
    /// * **Everywhere else it grades.** Each level short compounds —
    ///   `educationShortfallRatioDegree` (×0.30) a level for a degree-level role,
    ///   `educationShortfallRatioSubDegree` (×0.60) below that — down to
    ///   `educationShortfallFloor`, after `equivalentExperienceCredit` has made
    ///   up at most one level. Clearing the bar pays in a field the role accepts
    ///   (`relevantDegreeMultiplier`) and costs in an unrelated one
    ///   (`unrelatedDegreeMultiplier`). Meeting the bar only through equivalent
    ///   experience counts like an unrelated degree where the role lists
    ///   fields, and as neutral (×1) where it doesn't.
    func educationFactor(for player: Player) -> Double {
        if educationIsMandatory || player.isSimplified {
            return educationMet(for: player) ? 1.0 : 0.0
        }
        let required = requirements.education.minEQF
        guard required > 0 else { return 1.0 }
        if educationShortfall(for: player) == 0 {
            return (hasAcceptedDegree(for: player)
                ? GameConstants.relevantDegreeMultiplier
                : GameConstants.unrelatedDegreeMultiplier) * degreePreferenceFactor(for: player)
        }
        let credited = creditedEducationShortfall(for: player)
        guard credited > 0 else {
            let listsFields = !(requirements.education.acceptedProfiles ?? []).isEmpty
            return listsFields ? GameConstants.unrelatedDegreeMultiplier : 1.0
        }
        let ratio = required >= 5
            ? GameConstants.educationShortfallRatioDegree
            : GameConstants.educationShortfallRatioSubDegree
        return max(GameConstants.educationShortfallFloor, pow(ratio, Double(credited)))
    }

    /// Whether employers filling this role prefer a graduate even though the
    /// posting doesn't require one: well-paid office work below degree level.
    /// About half of insurance agents and sales representatives hold a
    /// bachelor's although BLS lists a high-school diploma as the entry
    /// requirement — "degree preferred" is how most such postings read.
    var prefersDegree: Bool {
        !educationIsMandatory && !isEntrepreneurial && workSetting == .office
            && requirements.education.minEQF < GameConstants.degreePreferredEQF
            && referenceIncome >= GameConstants.degreePreferredMinIncome
    }

    /// The penalty a non-graduate pays on a role that prefers a degree
    /// (`prefersDegree`): `degreePreferenceRatio` per level below a bachelor's,
    /// less any equivalent experience in the field. 1 for everyone else.
    func degreePreferenceFactor(for player: Player) -> Double {
        guard prefersDegree else { return 1.0 }
        let short = max(0, GameConstants.degreePreferredEQF - player.highestEQF
                        - equivalentExperienceCredit(for: player))
        return pow(GameConstants.degreePreferenceRatio, Double(short))
    }

    /// Experience as a multiplier: a modest edge beyond what the employer
    /// expects, and below it the square of the share held — but nothing at all
    /// under `experienceStretchMin` of it (see `experienceFactor(ratio:)`).
    /// Simplified mode keeps the all-or-nothing answer, so a young player sees
    /// "you qualify" or not.
    func experienceFactor(for player: Player) -> Double {
        let required = requirements.minYearsExperience
        guard required > 0 else { return 1.0 }
        if player.isSimplified { return experienceMet(for: player) ? 1.0 : 0.0 }
        return experienceFactor(ratio: Double(relevantYears(for: player)) / Double(required))
    }

    /// The realistic-mode experience factor for holding `ratio` of the stated
    /// years:
    ///
    /// * at or above the figure, up to `experienceVeteranMultiplier` for a
    ///   veteran;
    /// * from `experienceStretchMin` (0.6) up to it, `ratio²` — 4 of 5 years
    ///   ×0.64, 3 of 5 ×0.36 — a stretch hire, and a costly one;
    /// * below that, 0: the application isn't considered, which is what makes
    ///   the stated years a real requirement rather than a pro-rata discount.
    ///
    /// A seat-scarce role (C-suite, director, partner — see `seatScarcity`) is
    /// also closed while the factor is under `executiveExperienceMinFactor`: a
    /// CEO search doesn't look at someone with a fraction of the record.
    func experienceFactor(ratio: Double) -> Double {
        let factor: Double
        if ratio >= 1.0 {
            factor = min(GameConstants.experienceVeteranMultiplier,
                         1.0 + (ratio - 1.0) * GameConstants.experienceVeteranRate)
        } else if ratio < GameConstants.experienceStretchMin {
            factor = 0
        } else {
            factor = ratio * ratio
        }
        if seatScarcity != nil, factor < GameConstants.executiveExperienceMinFactor { return 0 }
        return factor
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

    /// What this employer offers the player: the posting's median scaled by
    /// the player's relevant years (`relevantYears`) —
    /// `offerExperienceBase + offerExperiencePerYear × years`, clamped to
    /// `offerExperienceBase…offerExperienceCap` — so a newcomer starts at 85% of
    /// the median and a ten-year veteran earns 115%. It is the salary a hire at
    /// a posted rate is paid, the negotiation slider's opening position, and
    /// the reference the salary ask is judged against.
    ///
    /// Built from the catalogue median (`income`), which is what every listing
    /// shows. Simplified keeps the money simple and pays the median; a founder
    /// isn't offered anything.
    func offeredSalary(for player: Player) -> Int {
        guard !player.isSimplified, !isEntrepreneurial else { return income }
        let years = Double(relevantYears(for: player))
        let share = min(GameConstants.offerExperienceCap,
                        max(GameConstants.offerExperienceBase,
                            GameConstants.offerExperienceBase + GameConstants.offerExperiencePerYear * years))
        // Never under the minimum wage: a newcomer's discount can't take a
        // low-paid job below the legal floor (it binds in Germany).
        return max(player.country.minimumAnnualPay, Int((Double(income) * share).rounded()))
    }

    /// How the salary asked for moves the odds, against the salary on offer
    /// (`offeredSalary`). A modest counter is expected and costs nothing (up to
    /// `GameConstants.salaryAskTolerance`); asking at or under
    /// `salaryAskDiscountRatio` earns a small edge; beyond the tolerance each
    /// point over costs `salaryAskPenaltyRate` points of odds.
    func salaryAlignmentFactor(requestedSalary: Double, offer: Double) -> Double {
        guard offer > 0 else { return 1.0 }
        let ratio = requestedSalary / offer
        if ratio <= GameConstants.salaryAskDiscountRatio { return GameConstants.salaryAskDiscountBonus }
        return max(0.0, 1.0 - max(0.0, ratio - GameConstants.salaryAskTolerance)
                   * GameConstants.salaryAskPenaltyRate)
    }

    // MARK: Hiring

    /// Every term of one application's odds, computed once in
    /// `Job.hireBreakdown` and read by everything that quotes them — the roll
    /// itself (`hireProbability`), the ⓘ breakdown in `JobDetail`, and the
    /// Career Advisor's estimates — so no two of them can show a different
    /// number from the one the game actually rolls.
    ///
    ///     merit = base + skill + prestige + network + fame + credential + breakthrough
    ///     raw   = merit × requirement factors × salary fit × demand × rung decay
    ///     final = clamp(raw × climate × time out of work,
    ///                   floor…ceiling) × seat
    ///
    /// A zero requirement factor closes the role (0); a breakthrough-gated
    /// career without its award sits at the floor; Simplified mode hires with
    /// certainty once the requirements are met; a founder venture's figure is
    /// its preparation (`founderSuccessProbability`) instead.
    struct HireBreakdown {
        // What the applicant brings — added together.
        /// Starting merit for the role's education level
        /// (`GameConstants.hireBaseByEQF`).
        let base: Double
        /// 0…1 soft-skill fit (`Job.softSkillFit`).
        let skillFit: Double
        /// The fit's contribution: `skillFit × GameConstants.hireSkillWeight`.
        let skill: Double
        /// Prestige of the best relevant degree's school.
        let prestige: Double
        /// Professional network in the field (`Player.networkBonus`).
        let network: Double
        /// Fame in the field's bucket (`Player.fameHireBonus`).
        let fame: Double
        /// A skill-building credential that covers the field
        /// (`Player.trainingCareerBonus`).
        let credential: Double
        /// The breakthrough award's bonus, when the career has one and it's held.
        let breakthrough: Double

        // How well the requirements are met — multiplied.
        /// Age, education, licences and experience (`Job.requirementFit`).
        let requirements: RequirementFit

        // The market — multiplied.
        /// How oversubscribed the role is (`JobCatalog.hiringDemandByBaseTitle`).
        let demand: Double
        /// `GameConstants.externalHireRungDecay` per rung above entry.
        let rungDecay: Double
        /// The salary on offer to this player (`Job.offeredSalary`) — the
        /// reference the ask is judged against.
        let offer: Double
        /// The salary ask (`Job.salaryAlignmentFactor`).
        let salaryFit: Double
        /// The employer industry's climate this year (`IndustryClimate.hireFactor`).
        let climate: Double
        /// Time out of work: each consecutive year unemployed beyond the first
        /// costs a little (`Player.unemploymentHireMultiplier`).
        let unemployment: Double
        /// Seat scarcity, applied after the floor (`Job.seatChance`).
        let seat: Double
        let floor: Double
        let ceiling: Double

        // How the final figure is decided.
        let isSimplified: Bool
        /// A breakthrough-gated career whose award isn't held.
        let breakthroughMissing: Bool
        /// A founder venture's odds, which replace the whole formula.
        let founderOdds: Double?

        /// Everything the applicant brings, before the requirements.
        var merit: Double { base + skill + prestige + network + fame + credential + breakthrough }

        /// Merit through the requirements, the salary ask and the market's shape,
        /// before the year's climate.
        var raw: Double { merit * requirements.factor * salaryFit * demand * rungDecay }

        /// `raw` through the climate and time out of work — the figure the floor
        /// and ceiling clamp.
        var scaled: Double { raw * climate * unemployment }

        /// The odds the game rolls.
        var final: Double { odds() }

        /// The odds with some terms swapped out — how the Career Advisor asks
        /// "what would they be once…?" without a second copy of the formula.
        /// `requirementFactor` replaces the product of the requirement factors
        /// (say, with the missing licence counted as held); `extraMerit` adds to
        /// what the applicant brings (a skill point more). With neither, this is
        /// `final`.
        func odds(requirementFactor: Double? = nil, extraMerit: Double = 0) -> Double {
            if let founderOdds { return founderOdds }
            let factor = requirementFactor ?? requirements.factor
            guard factor > 0 else { return 0 }
            if breakthroughMissing { return floor * seat }
            if isSimplified { return 1.0 }
            let value = (merit + extraMerit) * factor * salaryFit * demand * rungDecay
                * climate * unemployment
            return min(ceiling, max(floor, value)) * seat
        }
    }

    /// Starting merit for this role's education level
    /// (`GameConstants.hireBaseByEQF`).
    var hireBase: Double {
        let table = GameConstants.hireBaseByEQF
        return table[min(max(requirements.education.minEQF, 0), table.count - 1)]
    }

    /// How oversubscribed this role is, from `JobCatalog.hiringDemandByBaseTitle`
    /// (1.0 when unlisted).
    var hiringDemand: Double {
        JobCatalog.hiringDemandByBaseTitle[baseTitle] ?? 1.0
    }

    /// The narrowing pyramid on an outside application:
    /// `externalHireRungDecay` per rung above the ladder's entry.
    var externalHireRungDecay: Double {
        pow(GameConstants.externalHireRungDecay, Double(rung))
    }

    /// The base seat chance for a scarce seat, or nil for an ordinary role:
    /// `cSuiteSeatChance` for a "Chief …" title (CEO, CTO, Chief Medical
    /// Officer, Editor-in-Chief), `directorSeatChance` for a Director or Partner
    /// title. Founders make their own seat. Such seats also close to applicants
    /// well short of the expected years (see `experienceFactor(ratio:)`).
    var seatScarcity: Double? {
        guard !isEntrepreneurial else { return nil }
        if id.contains("Chief") { return GameConstants.cSuiteSeatChance }
        // A professional roster has a few dozen places per club and hundreds of
        // title-holding juniors chasing them.
        if baseTitle == "Player", rung >= 1 { return GameConstants.proRosterChance }  // i18n:ignore ids, never shown
        if id.contains("Director") || id.contains("Partner") { return GameConstants.directorSeatChance }
        return nil
    }

    /// The chance of clearing this role's seat hurdle — 1 for an ordinary role.
    /// On a commercial executive seat (`isExecutive`) a founder track record
    /// eases it (`Player.executiveTrackRecord`): a board hires people who have
    /// run a company. Read by hiring and by promotions into the seat alike.
    func seatChance(for player: Player) -> Double {
        guard let base = seatScarcity else { return 1.0 }
        return min(1.0, base + (isExecutive ? player.executiveTrackRecord : 0))
    }

    /// The seat on a *promotion* into this rung (see `Player.promotionOdds`):
    /// the hiring seat for a "Chief …", Director or Partner title
    /// (`seatChance`); `commandPostSeatChance` for a command post
    /// (`JobCatalog.commandPostTitles`); `leadershipSeatChance` for any other
    /// top rung (`isTopLeadership` — staff engineer, head chef, charge nurse);
    /// 1 for an ordinary rung. The top of a ladder has fewer seats than the
    /// people below it who are ready for one.
    func promotionSeatChance(for player: Player) -> Double {
        if seatScarcity != nil { return seatChance(for: player) }
        if JobCatalog.commandPostTitles.contains(id) { return GameConstants.commandPostSeatChance }
        if isTopLeadership { return GameConstants.leadershipSeatChance }
        return 1.0
    }

    /// Every term of an application at `requestedSalary` (see `HireBreakdown`).
    func hireBreakdown(for player: Player, requestedSalary: Double) -> HireBreakdown {
        hireBreakdown(for: player, requestedSalary: requestedSalary, requirements: requirementFit(for: player))
    }

    private func hireBreakdown(for player: Player, requestedSalary: Double,
                               requirements fit: RequirementFit) -> HireBreakdown {
        // Breakthrough gate: a career like Professional Player is effectively
        // closed without its signature fame award (a junior-competition win) —
        // odds sit at the floor no matter how skilled the applicant, in every
        // mode. Holding it opens the door and is the dominant term.
        let hasBreakthrough = breakthroughFame.map { key in
            player.fameAwards.contains { $0.key == key }
        }
        let skillFit = softSkillFit(for: player)
        let offer = Double(offeredSalary(for: player))
        return HireBreakdown(
            base: hireBase,
            skillFit: skillFit,
            skill: skillFit * GameConstants.hireSkillWeight,
            prestige: relevantPrestigeBonus(for: player),
            // A professional network in this field — built at its summits and
            // conferences — tilts the odds in the applicant's favour.
            network: player.networkBonus(for: category),
            // Industry-scoped fame opens doors in its own field only; top
            // leadership roles weight reputation more heavily.
            fame: player.fameHireBonus(for: category, topPosition: isTopLeadership),
            // A relevant skill-building credential (coding/game-dev/design/
            // production program) demonstrably helps land a role in its field.
            credential: player.trainingCareerBonus(for: category),
            breakthrough: hasBreakthrough == true ? Self.breakthroughBonus : 0.0,
            requirements: fit,
            demand: hiringDemand,
            rungDecay: externalHireRungDecay,
            offer: offer,
            salaryFit: salaryAlignmentFactor(requestedSalary: requestedSalary, offer: offer),
            // What this industry is doing this year: a booming field hires
            // people it would pass over in a slump (see `IndustryClimate`).
            climate: player.climate(for: industry).hireFactor,
            unemployment: player.unemploymentHireMultiplier,
            seat: seatChance(for: player),
            floor: GameConstants.hireFloor,
            ceiling: GameConstants.hireCeiling,
            isSimplified: player.isSimplified,
            breakthroughMissing: hasBreakthrough == false,
            // Founders aren't "hired" — their odds come from capital + founder
            // grit, previewed as if the target capital were fully funded.
            founderOdds: isEntrepreneurial
                ? founderSuccessProbability(for: player, investedCapital: targetCapital ?? 0)
                : nil
        )
    }

    /// The odds an application at `requestedSalary` succeeds — the rolled
    /// figure, `hireBreakdown(for:requestedSalary:).final`. A role a
    /// requirement closes is 0 whatever else the breakdown holds, so its other
    /// terms aren't scored (the advisor and the harness ask this of every
    /// posting, every year).
    func hireProbability(for player: Player, requestedSalary: Double) -> Double {
        let fit = requirementFit(for: player)
        if fit.isBlocked, !isEntrepreneurial { return 0 }
        return hireBreakdown(for: player, requestedSalary: requestedSalary, requirements: fit).final
    }

    // MARK: - Entrepreneurial path

    /// True for founder roles, which are gated on capital + grit rather than
    /// credentials. Identified by carrying a `targetCapital` (rather than by
    /// category) so founder roles can live under the Business category.
    var isEntrepreneurial: Bool { targetCapital != nil }

    /// A venture that can scale — software and games sell the same product to
    /// any number of customers — so it can raise investment and, rarely, break
    /// out. A restaurant or a studio grows one location at a time.
    /// The industries this role can be posted in (see
    /// `JobCatalog.industries(forBaseTitle:category:)`).
    var possibleIndustries: [Industry] {
        JobCatalog.industries(forBaseTitle: baseTitle, category: category)
    }

    /// Whether the player chooses the employer's industry when applying.
    /// Administration roles exist in every kind of organisation — a hospital, a
    /// bank, a city hall — so the player picks which to apply to rather than
    /// taking the one sector a year's posting happens to name.
    var offersIndustryChoice: Bool {
        category == .administration && possibleIndustries.count > 1
    }

    /// This posting at an employer in `industry`.
    func inIndustry(_ industry: Industry) -> Job {
        var copy = self
        copy.industry = industry
        return copy
    }

    var isScalableVenture: Bool {
        isEntrepreneurial && JobCatalog.scalableVentureTitles.contains(baseTitle)
    }

    /// True for a senior seat where equity/strategy plays make sense — the roles
    /// that unlock the Boardroom (`ExecutiveDecision`). Covers every founder
    /// venture plus the top leadership seat of a business-style track (the
    /// C-suite and the director capstones in Business/Entrepreneurship/
    /// Technology). A Head Chef or Charge Nurse tops out their ladder too, but
    /// doesn't run a cap table — so `isTopLeadership` alone isn't enough.
    ///
    /// Two kinds of apex are *not* executive seats even in those fields, though
    /// they stay `isTopLeadership` for Simplified's goal: the individual-
    /// contributor rungs (Staff, Principal and Lead — a principal engineer
    /// designs the architecture, they don't run the company) and the
    /// operations-manager capstone (~3.5M US jobs — middle management, not the
    /// boardroom).
    var isExecutive: Bool {
        if isEntrepreneurial { return true }
        guard isTopLeadership else { return false }
        guard !Job.individualContributorApexLabels.contains(rungLabel),
              !Job.nonExecutiveCapstones.contains(id) else { return false }
        switch category {
        case .business, .entrepreneurship, .technology:
            return true
        default:
            return false
        }
    }

    /// Apex rung labels that lead work rather than a company (see `isExecutive`).
    private static let individualContributorApexLabels: Set<String> = ["Staff", "Principal", "Lead"]  // i18n:ignore ids, never shown

    /// Top-leadership capstones that are middle management, not executive seats.
    private static let nonExecutiveCapstones: Set<String> = ["Operations Manager"]  // i18n:ignore ids, never shown

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
        "Judge",  // i18n:ignore ids, never shown
    ]

    /// Whether this is unskilled work — a role requiring no post-secondary
    /// education or training (below `GameConstants.promotionMinEQF`). Its merit
    /// raises stop at the lower pay band (`payCeilingMultipleSubDegree`); it is
    /// promoted like any other rung where a ladder has one above it (a patrol
    /// officer, an apprentice), and a standalone unskilled role — like any
    /// standalone role — has no rung to be promoted to.
    /// Founder ventures are exempt: they carry `minEQF: 0` because founders
    /// aren't gated on degrees, not because the work is unskilled.
    var isLowSkilled: Bool {
        !isEntrepreneurial && requirements.education.minEQF < GameConstants.promotionMinEQF
    }

    /// The founder's **preparation score** (0.03...`founderMaxSuccess`). A
    /// business always opens; this sets how well it survives — the yearly fold
    /// risk and the breakout chance (see `Player.founderPreparation` and
    /// `Player.ventureFoldRisk`). Driven by *who the founder is*, not their bank
    /// balance: experience in the venture's own industry and
    /// how well their soft skills fit what the business demands are the two big
    /// levers, with the size of the stake a supporting factor.
    ///
    /// **Capital is the only hard requirement.** Anyone with a stake may try
    /// anything — nobody is barred from opening a restaurant for never having
    /// worked in hospitality, it is simply far more likely to fold. The
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
        // Experience in the industry still leads — it's the strongest predictor
        // of a founder's success in real life — but the skills a business runs
        // on pull nearly level with it.
        let experience = founderExperienceFit(for: player) * 0.22   // up to +22%
        let skill = founderSkillFit(for: player) * 0.26             // up to +26%
        let capitalRatio = Double(investedCapital) / Double(target)
        let capital = min(capitalRatio, 1.0) * 0.09                 // up to +9%
        // A relevant skill-building credential (e.g. a Coding Bootcamp for a SaaS
        // startup, a Game Dev Program for an indie studio) lifts a founder's odds.
        let credential = player.trainingCareerBonus(for: category) // up to +10%
        // A business name: years running ventures, rounds closed and exits
        // made. Serial founders start their next venture better placed.
        let reputation = min(GameConstants.founderReputationCap,
                             player.famePoints(for: .business) * GameConstants.founderReputationPerPoint)
        // Founding into a contracting market is the harder version of the same
        // bet — customers and backers are scarcer in a slump.
        let climate = player.climate(for: industry).hireFactor
        let raw = (0.05 + experience + skill + capital + credential + reputation) * climate
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
    /// Visionary (ambition and initiative) and Persuader traits every founder
    /// leans on regardless of field. The field-specific profile is weighted a little more.
    func founderSkillFit(for player: Player) -> Double {
        let p = player.softSkills

        // The same graded profile term the hiring path uses — a venture asks
        // for the skills its business demands the way an employer does.
        let profileFit = softSkillFit(for: player)

        let gritKeys: [WritableKeyPath<SoftSkills, Int>] = [
            \.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
        ]
        let grit = gritKeys.reduce(0.0) { acc, kp in
            acc + min(Double(p[keyPath: kp]) / 6.0, 1.0)
        } / Double(gritKeys.count)

        return profileFit * 0.6 + grit * 0.4
    }

    /// Hire-probability bonus from the player's most prestigious *relevant* degree.
    /// Prefers degrees in the job's accepted profiles when such a list is set.
    func relevantPrestigeBonus(for player: Player) -> Double {
        // Only a college degree carries a school's name — a high-school diploma
        // is stored with a default tier but earns no prestige.
        let eligible = player.degrees.filter { $0.profile != nil && $0.eqf >= requirements.education.minEQF }
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
        return Job.prestigeBonus(forPrestige: pool.map { $0.tier.prestige }.max() ?? 0)
    }

    /// What a school of `prestige` adds to a hire (`EducationTier.prestige`):
    /// Elite +0.10, State +0.05, Community and unranked nothing.
    static func prestigeBonus(forPrestige prestige: Int) -> Double {
        switch prestige {
        case 3:  return 0.10
        case 2:  return 0.05
        default: return 0.0
        }
    }

    /// The most merit raises can take this role's pay to: its catalogue median
    /// times `payCeilingMultipleSubDegree` below EQF 4, `payCeilingMultipleSkilled`
    /// from it — the top of the band. See `Player.stepRaise`.
    var payCeiling: Int {
        let multiple = requirements.education.minEQF >= GameConstants.promotionMinEQF
            ? GameConstants.payCeilingMultipleSkilled
            : GameConstants.payCeilingMultipleSubDegree
        return Int((Double(income) * multiple).rounded())
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
    /// Whether this job sits *above* the entry rung of its ladder.
    ///
    /// Position, not the label. It used to ask whether the title carried a
    /// seniority word, which quietly exempted every rung that tops its ladder
    /// under a name of its own: an Airline Captain, a Supply Chain Manager and
    /// an Editor-in-Chief all read as standalone roles, so their experience bar
    /// was satisfied by *any* years in the category — eight years of moving
    /// furniture qualified you to command a flight deck. A rung is a rung
    /// whether or not anyone wrote "Senior" on it.
    var isLadderVariant: Bool { rung > 0 }

    /// Player-facing label for this seniority level. "Standard" for the rung
    /// that carries the bare role name.
    var seniorityLabel: String {
        rungLabel.isEmpty
            ? String(localized: "Standard", comment: "The seniority of a job that is the plain role with no Senior, Lead or Junior in front. Next to labels like Senior and Lead.")  // i18n:ignore translator comment
            : displayRungLabel
    }

    /// Player-facing occupation title. Founding a venture makes the player its
    /// CEO, so an entrepreneurial occupation reads "CEO, <Venture>" rather than
    /// the bare venture name (`baseTitle` stays the venture for experience and
    /// catalogue lookups).
    var displayTitle: String {
        isEntrepreneurial ? L("CEO, \(catalogueTitle)") : catalogueTitle
    }

    /// Apex seniority prefixes that represent the top rung of a career ladder.
    private static let leadershipPrefixes: Set<String> = [
        "Lead", "Principal", "Staff", "Head", "Executive", "Master", "Charge", "Chief"  // i18n:ignore ids, never shown
    ]

    /// Title keywords that mark a top leadership role even without a seniority
    /// prefix (e.g. "Marketing Director", "Managing Partner", chiefs). Tracks that
    /// top out with a `Lead`/`Head`/`Principal` prefix instead are covered by
    /// `leadershipPrefixes`; this list catches the keyword-only apexes.
    private static let leadershipKeywords: [String] = [
        "Director", "Partner", "Chief"  // i18n:ignore ids, never shown
    ]

    /// Track apexes listed explicitly because their titles carry no leadership
    /// prefix/keyword — and to avoid sweeping in their mid-level rungs (e.g.
    /// Hotel/Sales/Project Manager, or Startup Founder below Serial Entrepreneur).
    private static let capstoneTitles: Set<String> = [
        "Store Manager", "Operations Manager", "Farm Manager", "Serial Entrepreneur"  // i18n:ignore ids, never shown
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
            collaborationAndTeamwork: 0,
            timeManagementAndPlanning: 0,
            selfDisciplineAndPerseverance: 0
        ),
        hardSkills: .init(trainings: [])
    ),
)

