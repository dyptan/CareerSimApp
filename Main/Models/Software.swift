import Foundation

enum Software: String, CaseIterable, Codable, Hashable, Identifiable {
    case officeSuite = "Office"
    case gameEngine = "Game Engine"
    case mediaEditing = "Photo/Video Editing"
    case programming = "Programming"
    case cad = "CAD"
    case accounting = "Accounting"
    case musicProduction = "Music Production"
    case dataAnalytics = "Data Analytics"
    case crm = "CRM"
    case gis = "GIS"

    var id: String { rawValue }

    /// Plain-language explanation of the software category, for the in-game info popover.
    var description: String {
        switch self {
        case .officeSuite: return "Word processor, spreadsheets, and presentation tools (like Microsoft Office or Google Workspace). Used in nearly every office job."
        case .gameEngine: return "Tools like Unity or Unreal for making video games. Required for game-developer roles."
        case .mediaEditing: return "Photo and video editing tools (like Photoshop or Premiere). Used by designers, marketers, and content creators."
        case .programming: return "Writing code in languages like Python, Swift, or JavaScript. Foundation for most tech jobs."
        case .cad: return "Computer-Aided Design tools (like AutoCAD or SolidWorks) for technical drawings and 3D models. Used by engineers, architects, and product designers."
        case .accounting: return "Bookkeeping and tax software (like QuickBooks or Xero). Used in business, finance, and any job that tracks money."
        case .musicProduction: return "Digital audio workstations (like Logic Pro, Ableton, or GarageBand) for recording and mixing music. Used by musicians, producers, and sound designers."
        case .dataAnalytics: return "Tools like Excel, SQL, Python pandas, Tableau, and Power BI for cleaning data and turning it into charts. Standard kit for analysts, scientists, and operations roles."
        case .crm: return "Customer Relationship Management software (like Salesforce or HubSpot) for tracking leads, deals, and clients. Backbone of sales, marketing, and recruiting."
        case .gis: return "Geographic Information Systems (like ArcGIS or QGIS) for mapping and analysing location data. Used by environmental scientists, urban planners, and civil engineers."
        }
    }

    /// Friendly display name for the software category.
    var friendlyName: String {
        switch self {
        case .officeSuite: return "Office Suite"
        case .gameEngine: return "Game Engine"
        case .mediaEditing: return "Photo / Video Editing"
        case .programming: return "Programming"
        case .cad: return "CAD Software"
        case .accounting: return "Accounting Software"
        case .musicProduction: return "Music Production"
        case .dataAnalytics: return "Data Analytics"
        case .crm: return "CRM Software"
        case .gis: return "GIS Mapping"
        }
    }

    var pictogram: String {
        switch self {
        case .officeSuite: return "📊"
        case .gameEngine: return "🕹️"
        case .mediaEditing: return "🖌️"
        case .programming: return "💻"
        case .cad: return "📐"
        case .accounting: return "🧾"
        case .musicProduction: return "🎚️"
        case .dataAnalytics: return "📊"
        case .crm: return "📇"
        case .gis: return "🗺️"
        }
    }

    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .officeSuite:
            return [
                (\.selfDisciplineAndPerseverance, 2),
                (\.timeManagementAndPlanning, 1),
            ]
        case .programming:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .mediaEditing:
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .gameEngine:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.creativityAndInsightfulThinking, 3),
            ]
        case .cad:
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .accounting:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .musicProduction:
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.selfDisciplineAndPerseverance, 2),
            ]
        case .dataAnalytics:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .crm:
            return [
                (\.communicationAndNetworking, 2),
                (\.timeManagementAndPlanning, 2),
            ]
        case .gis:
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        }
    }

    func softwareRequirements(_ player: Player) -> TrainingRequirementResult {
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }
        return .ok(cost: 0)
    }
}
