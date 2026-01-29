import Foundation

/// Represents the general tier of a company for a given job.
/// Adjust cases as needed to match your data set.
enum CompanyTier: String, Codable, Hashable, CaseIterable {
    case startup
    case mid
    case enterprise
    case government

    var displayName: String {
        switch self {
        case .startup: return "Startup"
        case .government: return "Government"
        case .mid:
            return "Medium size company"
        case .enterprise:
            return "Large enterprise"
        }
    }
}

struct Job: Identifiable, Codable, Hashable {
    let id: String
    let category: JobCategory
    let income: Int            // full dollars per year (e.g., 72000)
    let summary: String
    let icon: String
    let requirements: Requirements
    let companyTier: CompanyTier?   // NEW (optional for back-compat)
    let version: Int

    struct Requirements: Codable, Hashable {
        let education: Education
        let softSkills: SoftSkillsBlock
        let hardSkills: HardSkillsBlock
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

        // Matches keys from dataV5.json
        struct SoftSkillsBlock: Codable, Hashable {
            let analyticalReasoningAndProblemSolving: Int
            let creativityAndInsightfulThinking: Int
            let communicationAndNetworking: Int
            let leadershipAndInfluence: Int
            let courageAndRiskTolerance: Int
            let spacialNavigation: Int
            let carefulnessAndAttentionToDetail: Int
            let perseveranceAndGrit: Int
            let tinkeringAndFingerPrecision: Int
            let physicalStrength: Int
            let coordinationAndBalance: Int
            let resilienceAndEndurance: Int
        }

        struct HardSkillsBlock: Codable, Hashable {
            let certifications: [String]
            let licenses: [String]
            let software: [String]
            let portfolio: [String]
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
            courageAndRiskTolerance: 1,
            spacialNavigation: 1,
            carefulnessAndAttentionToDetail: 1,
            perseveranceAndGrit: 1,
            tinkeringAndFingerPrecision: 1,
            physicalStrength: 1,
            coordinationAndBalance: 1,
            resilienceAndEndurance: 1
        ),
        hardSkills: .init(certifications: ["AWS"], licenses: ["C"], software: ["Office 365"], portfolio: [])
    ),
    companyTier: .startup,
    version: 5
)

