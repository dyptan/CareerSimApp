import Foundation

enum CompanyTier: String, Codable, Hashable, CaseIterable {
    case selfEmployed   // freelancer, independent contractor, sole trader
    case smallBusiness  // family-owned shop, local tradesperson, small restaurant
    case startup        // early-stage, typically VC-backed or bootstrapped
    case mid            // mid-market company, ~50–500 employees
    case enterprise     // large corporation, 500+ employees
    case government     // public sector, municipal, state, or federal
    case nonprofit      // NGO, charity, foundation

    var displayName: String {
        switch self {
        case .selfEmployed:  return "Self-Employed"
        case .smallBusiness: return "Small Business"
        case .startup:       return "Startup"
        case .mid:           return "Mid-Market"
        case .enterprise:    return "Large Enterprise"
        case .government:    return "Government"
        case .nonprofit:     return "Nonprofit / NGO"
        }
    }

    /// Multiplier applied to the job's base income.
    /// Reflects how each employment context shifts actual take-home pay
    /// relative to the published median (1.0 = no adjustment).
    var salaryMultiplier: Double {
        switch self {
        case .selfEmployed:  return 0.85  // variable income, no benefits, dry spells
        case .smallBusiness: return 0.90  // below-market pay, limited benefits
        case .startup:       return 1.05  // competitive cash + equity upside
        case .mid:           return 1.00  // baseline — median salaries are calibrated here
        case .enterprise:    return 1.20  // top-of-market comp, bonuses, full benefits
        case .government:    return 0.95  // slightly below market, offset by stability/pension
        case .nonprofit:     return 0.78  // notoriously underpaid relative to skills required
        }
    }

    /// Randomly picks a plausible tier for a job given its category and income.
    static func random(category: JobCategory, income: Int) -> CompanyTier {
        switch category {
        case .publicServices, .education:
            return .government
        case .arts, .media, .fashion:
            return [CompanyTier.selfEmployed, .selfEmployed, .smallBusiness].randomElement()!
        case .agriculture:
            return income >= 60_000
                ? [CompanyTier.mid, .smallBusiness].randomElement()!
                : [CompanyTier.selfEmployed, .smallBusiness].randomElement()!
        case .health:
            return income >= 130_000
                ? [CompanyTier.enterprise, .government].randomElement()!
                : .government
        case .service, 
                .construction where income < 50_000:
            return [CompanyTier.smallBusiness, .selfEmployed].randomElement()!
        default:
            if income >= 100_000 { return [CompanyTier.enterprise, .mid].randomElement()! }
            if income >= 60_000  { return [CompanyTier.mid, .enterprise, .startup].randomElement()! }
            if income >= 38_000  { return [CompanyTier.smallBusiness, .mid].randomElement()! }
            return [CompanyTier.startup, .smallBusiness].randomElement()!
        }
    }

    /// Annual probability (0–1) that the player loses this job unexpectedly.
    /// Used each in-game year to roll for involuntary job loss.
    var riskFactor: Double {
        switch self {
        case .selfEmployed:  return 0.18  // contracts end, clients disappear, dry seasons
        case .smallBusiness: return 0.12  // small firms close or downsize frequently
        case .startup:       return 0.22  // high failure rate, funding rounds, pivots
        case .mid:           return 0.06  // moderate stability, occasional restructuring
        case .enterprise:    return 0.04  // large firms restructure slowly; layoffs are rare
        case .government:    return 0.01  // near-permanent employment, very hard to lose
        case .nonprofit:     return 0.09  // funding cuts can eliminate roles quickly
        }
    }

    /// Big formal employers screen by paper credentials (certifications) — the role
    /// only opens for applicants who hold the listed certs. Smaller organisations
    /// hire on demonstrated work instead, so they look at the player's portfolio.
    var hiringSignal: HiringSignal {
        switch self {
        case .enterprise, .government: return .credentials
        default:                       return .portfolio
        }
    }

    enum HiringSignal {
        /// Certifications act as a hard gate (HR-driven hiring).
        case credentials
        /// Portfolio items act as a hard gate (work-driven hiring).
        case portfolio
    }

    /// Hire-probability modifier: harder to land a job at selective tiers,
    /// easier at small / self-employment tiers.
    var hireDifficulty: Double {
        switch self {
        case .selfEmployed:  return 0.20
        case .smallBusiness: return 0.10
        case .nonprofit:     return 0.05
        case .government:    return 0.00
        case .mid:           return 0.00
        case .startup:       return -0.05
        case .enterprise:    return -0.10
        }
    }

    /// Plausible tiers a player could realistically apply to for a given job category and salary.
    /// Mirrors the heuristics in `random(category:income:)` but returns all candidates.
    static func plausibleTiers(category: JobCategory, income: Int) -> [CompanyTier] {
        switch category {
        case .publicServices, .education:
            return [.government, .nonprofit]
        case .arts, .media, .fashion:
            return [.selfEmployed, .smallBusiness, .startup]
        case .agriculture:
            return income >= 60_000
                ? [.smallBusiness, .mid, .selfEmployed]
                : [.selfEmployed, .smallBusiness]
        case .health:
            return income >= 130_000
                ? [.enterprise, .government, .nonprofit]
                : [.government, .nonprofit, .smallBusiness]
        case .service:
            return [.smallBusiness, .selfEmployed, .mid]
        case .construction where income < 50_000:
            return [.smallBusiness, .selfEmployed, .mid]
        default:
            if income >= 100_000 { return [.enterprise, .mid, .startup] }
            if income >= 60_000  { return [.mid, .enterprise, .startup, .smallBusiness] }
            if income >= 38_000  { return [.smallBusiness, .mid, .startup] }
            return [.smallBusiness, .startup, .selfEmployed]
        }
    }
}

struct Job: Identifiable, Codable, Hashable {
    let id: String
    let category: JobCategory
    let income: Int            // base/reference salary shown in job listings
    let summary: String
    let icon: String
    let requirements: Requirements
    var companyTier: CompanyTier
    var annualIncome: Int      // actual pay locked in when the job was taken

    init(id: String, category: JobCategory, income: Int, summary: String, icon: String,
         requirements: Requirements) {
        self.id = id
        self.category = category
        self.income = income
        self.summary = summary
        self.icon = icon
        self.requirements = requirements
        let tier = CompanyTier.random(category: category, income: income)
        self.companyTier = tier
        let variance = category.salaryVariance
        let factor = Double.random(in: (1.0 - variance)...(1.0 + variance))
        self.annualIncome = Int(Double(income) * tier.salaryMultiplier * factor)
    }

    struct Requirements: Codable, Hashable {
        let education: Education
        let softSkills: SoftSkills
        let hardSkills: HardSkills
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
    /// Soft-skill keypaths counted by the hire-probability score.
    /// 15 entries; do not change without updating hire-probability divisor.
    private static let scoredSoftSkills: [WritableKeyPath<SoftSkills, Int>] = [
        \.analyticalReasoningAndProblemSolving,
        \.creativityAndInsightfulThinking,
        \.communicationAndNetworking,
        \.leadershipAndInfluence,
        \.visionaryThinkingAndAmbition,
        \.spacialNavigationAndOrientation,
        \.carefulnessAndAttentionToDetail,
        \.tinkeringAndFingerPrecision,
        \.resilienceAndEndurance,
        \.outdoorAndWeatherResilience,
        \.stressResistanceAndEmotionalRegulation,
        \.collaborationAndTeamwork,
        \.timeManagementAndPlanning,
        \.selfDisciplineAndPerseverance,
        \.presentationAndStorytelling,
    ]

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

    func hardSkillsMet(for player: Player) -> Bool {
        let req = effectiveRequirements.hardSkills
        // Licenses are always required (legally enforced regardless of employer).
        guard req.licenses.isSubset(of: player.hardSkills.licenses) else {
            return false
        }
        // Big formal employers gate on certifications; smaller employers gate on portfolio.
        switch companyTier.hiringSignal {
        case .credentials:
            return req.certifications.isSubset(of: player.hardSkills.certifications)
        case .portfolio:
            return req.portfolioItems.isSubset(of: player.hardSkills.portfolioItems)
        }
    }

    /// Extra certifications that enterprise / government employers layer on top
    /// of the catalog baseline. Smaller employers don't bother with these.
    static func enterpriseExtras(for category: JobCategory) -> Set<Certification> {
        switch category {
        case .technology:                                  return [.security, .scrum]
        case .business:                                    return [.pmp, .shrm]
        case .finance:                                     return [.cpa, .cfa]
        case .engineering:                                 return [.pmp]
        case .construction, .manufacturing, .automotive:   return [.osha10]
        default:                                           return []
        }
    }

    /// Requirements adjusted for the offer's company tier. Enterprise / government
    /// listings layer in additional certifications on top of the catalog baseline;
    /// other tiers see the unmodified requirements.
    var effectiveRequirements: Requirements {
        let extras = Self.enterpriseExtras(for: category)
        guard companyTier.hiringSignal == .credentials, !extras.isEmpty else { return requirements }
        let merged = requirements.hardSkills.certifications.union(extras)
        return Requirements(
            education: requirements.education,
            softSkills: requirements.softSkills,
            hardSkills: HardSkills(
                portfolioItems: requirements.hardSkills.portfolioItems,
                certifications: merged,
                licenses: requirements.hardSkills.licenses
            )
        )
    }

    func allRequirementsMet(for player: Player) -> Bool {
        // Emphasize degree + hard skills; soft skills are helpful only.
        educationMet(for: player) && hardSkillsMet(for: player)
    }

    func salaryAlignmentFactor(requestedSalary: Double) -> Double {
        let ratio = requestedSalary / Double(annualIncome)
        if ratio <= 1.0 { return 1.0 }
        // Asking more than budget: probability drops steeply above 33% excess.
        return max(0.0, 1.0 - (ratio - 1.0) * 3.0)
    }

    func hireProbability(for player: Player, requestedSalary: Double) -> Double {
        guard allRequirementsMet(for: player) else { return 0.0 }
        let skillScore = Double(softSkillsHelpfulScore(for: player)) / Double(Self.scoredSoftSkills.count)
        let prestige = relevantPrestigeBonus(for: player)
        let tierDifficulty = companyTier.hireDifficulty
        let raw = (0.2 + skillScore * 0.7 + prestige + tierDifficulty)
            * salaryAlignmentFactor(requestedSalary: requestedSalary)
        return max(0.05, min(0.95, raw))
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

    /// Returns one Job per plausible employer tier, with deterministic salary
    /// (no random variance) so the player can compare offers side-by-side.
    func tieredOffers() -> [Job] {
        CompanyTier.plausibleTiers(category: category, income: income).map { tier in
            var copy = self
            copy.companyTier = tier
            copy.annualIncome = Int(Double(income) * tier.salaryMultiplier)
            return copy
        }
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
        hardSkills: .init(
            portfolioItems: [],
            certifications: [],
            licenses: []
        )
    ),
)

