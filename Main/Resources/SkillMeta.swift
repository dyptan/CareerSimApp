import Foundation

struct SkillRef: Codable, Hashable {
    let id: String
    let level: Int
}

enum HardSkillType: String, Codable, Hashable {
    case software
    case certification
    case license
    case portfolio
    case other
}

struct SkillMeta: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let asset: String?
    let type: HardSkillType?
}
