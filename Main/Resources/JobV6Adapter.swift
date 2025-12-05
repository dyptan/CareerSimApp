import Foundation

// DTOs that mirror the denormalized dataV6.json shape
private struct JobV6: Decodable {
    let id: String
    let category: String
    let income: Int
    let summary: String
    let icon: String
    let requirements: Requirements
    let companyTier: String?   // NEW
    let version: Int

    struct Requirements: Decodable {
        let education: Education
        let softSkills: [SoftSkillItem]
        let hardSkills: [HardSkillItem]

        struct Education: Decodable {
            let minEQF: Int
            let acceptedProfiles: [String]?
        }

        struct SoftSkillItem: Decodable {
            let id: String
            let name: String
            let level: Int
            let description: String?
            let rationale: String?
        }

        struct HardSkillItem: Decodable {
            let id: String
            let name: String
            let level: Int
            let description: String?
            let rationale: String?
        }
    }
}

enum CompanyTier: String, Codable, Hashable, CaseIterable, Identifiable {
    case startup
    case smb
    case midMarket
    case enterprise
    case government
    case nonprofit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .startup: return "Startup"
        case .smb: return "SMB"
        case .midMarket: return "Mid‑Market"
        case .enterprise: return "Enterprise"
        case .government: return "Government"
        case .nonprofit: return "Nonprofit"
        }
    }

    var badgeColor: (fg: String, bgOpacity: Double) {
        switch self {
        case .startup: return ("blue", 0.15)
        case .smb: return ("teal", 0.15)
        case .midMarket: return ("indigo", 0.15)
        case .enterprise: return ("purple", 0.15)
        case .government: return ("orange", 0.15)
        case .nonprofit: return ("pink", 0.15)
        }
    }
}

enum JobV6Adapter {
    static func loadJobs(from url: URL) throws -> [Job] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let v6 = try decoder.decode([JobV6].self, from: data)
        return v6.compactMap(mapToJob)
    }

    // Map V6 into existing Job (compat mode)
    private static func mapToJob(_ src: JobV6) -> Job? {
        guard let cat = Category(rawValue: src.category) else { return nil }

        // Education
        let acceptedProfiles: [TertiaryProfile]? = src.requirements.education.acceptedProfiles?
            .compactMap { TertiaryProfile(rawValue: $0) }
        let edu = Job.Requirements.Education(
            minEQF: src.requirements.education.minEQF,
            acceptedProfiles: acceptedProfiles
        )

        // Soft skills
        func softLevel(_ id: String) -> Int {
            src.requirements.softSkills.first(where: { $0.id == id })?.level ?? 0
        }
        let soft = Job.Requirements.SoftSkillsBlock(
            analyticalReasoningAndProblemSolving: softLevel("analyticalReasoning"),
            creativityAndInsightfulThinking: softLevel("creativity"),
            communicationAndNetworking: softLevel("communication"),
            leadershipAndInfluence: softLevel("leadership"),
            courageAndRiskTolerance: softLevel("riskTolerance"),
            spacialNavigation: softLevel("spatialNavigation"),
            carefulnessAndAttentionToDetail: softLevel("attentionToDetail"),
            perseveranceAndGrit: softLevel("perseverance"),
            tinkeringAndFingerPrecision: softLevel("tinkering"),
            physicalStrength: softLevel("strength"),
            coordinationAndBalance: softLevel("coordination"),
            resilienceAndEndurance: softLevel("endurance")
        )

        // Hard skills
        var certs: [String] = []
        var licenses: [String] = []
        var software: [String] = []
        var portfolio: [String] = []

        for item in src.requirements.hardSkills {
            switch item.id {
            case "drivers": licenses.append("B")
            case "cdl": licenses.append("CE")
            case "rn": licenses.append("RN")
            case "electrician": licenses.append("EL")
            case "plumber": licenses.append("PL")
            case "office": software.append("Office")
            case "programming": software.append("Programming")
            case "mediaEditing": software.append("Photo/Video Editing")
            case "gameEngine": software.append("Game Engine")
            case "security": certs.append("Security")
            case "appPortfolio": portfolio.append("App")
            case "gamePortfolio": portfolio.append("Game")
            case "websitePortfolio": portfolio.append("Website")
            case "libraryPortfolio": portfolio.append("Library")
            case "paperPortfolio": portfolio.append("Paper")
            case "presentationPortfolio": portfolio.append("Presentation")
            default:
                let n = item.name
                if ["B", "Driver's License"].contains(n) { licenses.append("B") }
                else if ["CE", "CDL"].contains(n) { licenses.append("CE") }
                else if ["RN", "Nurse", "Nurse License"].contains(n) { licenses.append("RN") }
                else if ["EL", "Electrician License"].contains(n) { licenses.append("EL") }
                else if ["PL", "Plumber License"].contains(n) { licenses.append("PL") }
                else if ["Office"].contains(n) { software.append("Office") }
                else if ["Programming"].contains(n) { software.append("Programming") }
                else if ["Photo/Video Editing"].contains(n) { software.append("Photo/Video Editing") }
                else if ["Game Engine"].contains(n) { software.append("Game Engine") }
                else if ["Security"].contains(n) { certs.append("Security") }
                else if ["App", "Game", "Website", "Library", "Paper", "Presentation"].contains(n) {
                    portfolio.append(n)
                } else {
                    continue
                }
            }
        }

        let hard = Job.Requirements.HardSkillsBlock(
            certifications: certs,
            licenses: licenses,
            software: software,
            portfolio: portfolio
        )

        // Map company tier string -> enum
        let tier: CompanyTier? = src.companyTier.flatMap { CompanyTier(rawValue: $0) }

        return Job(
            id: src.id,
            category: cat,
            income: src.income,
            summary: src.summary,
            icon: src.icon,
            requirements: .init(education: edu, softSkills: soft, hardSkills: hard),
            companyTier: tier,   // NEW
            version: src.version
        )
    }
}
