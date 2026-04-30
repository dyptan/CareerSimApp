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
            software: [],
            licenses: []
        )
    ),
)

