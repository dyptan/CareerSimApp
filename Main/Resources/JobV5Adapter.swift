import Foundation

// DTOs that mirror dataV5.json
private struct JobV5: Decodable {
    let id: String
    let category: String
    let income: Int
    let summary: String
    let icon: String
    let requirements: Requirements
    let version: Int

    struct Requirements: Decodable {
        let education: Education
        let softSkills: SoftSkills
        let hardSkills: HardSkills?

        struct Education: Decodable {
            let minEQF: Int
            let acceptedProfiles: [String]?
        }

        struct SoftSkills: Decodable {
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

        struct HardSkills: Decodable {
            let certifications: [String]
            let licenses: [String]
            let software: [String]
            let portfolio: [String]
        }
    }
}

enum JobV5Adapter {
    static func loadJobs(from url: URL) throws -> [Job] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let v5 = try decoder.decode([JobV5].self, from: data)
        return v5.compactMap(mapToJob)
    }

    private static func mapToJob(_ src: JobV5) -> Job? {
        guard let cat = Category(rawValue: src.category) else {
            // Unknown category string; drop or default
            return nil
        }

        // Education
        let acceptedProfiles: [TertiaryProfile]? = src.requirements.education.acceptedProfiles?
            .compactMap { TertiaryProfile(rawValue: $0) }
        let edu = Job.Requirements.Education(
            minEQF: src.requirements.education.minEQF,
            acceptedProfiles: acceptedProfiles
        )

        // Soft skills block
        let s = src.requirements.softSkills
        let soft = Job.Requirements.SoftSkillsBlock(
            analyticalReasoningAndProblemSolving: s.analyticalReasoningAndProblemSolving,
            creativityAndInsightfulThinking: s.creativityAndInsightfulThinking,
            communicationAndNetworking: s.communicationAndNetworking,
            leadershipAndInfluence: s.leadershipAndInfluence,
            courageAndRiskTolerance: s.courageAndRiskTolerance,
            spacialNavigation: s.spacialNavigation,
            carefulnessAndAttentionToDetail: s.carefulnessAndAttentionToDetail,
            perseveranceAndGrit: s.perseveranceAndGrit,
            tinkeringAndFingerPrecision: s.tinkeringAndFingerPrecision,
            physicalStrength: s.physicalStrength,
            coordinationAndBalance: s.coordinationAndBalance,
            resilienceAndEndurance: s.resilienceAndEndurance
        )

        // Hard skills block (optional in JSON; default to empty arrays)
        let h = src.requirements.hardSkills
        let hard = Job.Requirements.HardSkillsBlock(
            certifications: h?.certifications ?? [],
            licenses: h?.licenses ?? [],
            software: h?.software ?? [],
            portfolio: h?.portfolio ?? []
        )

        let req = Job.Requirements(
            education: edu,
            softSkills: soft,
            hardSkills: hard
        )

        // Use full dollars (no division)
        return Job(
            id: src.id,
            category: cat,
            income: src.income,
            summary: src.summary,
            icon: src.icon,
            requirements: req,
            version: src.version
        )
    }
}
