//import Foundation
//
//struct SkillsRegistry {
//    let soft: [String: SkillMeta]
//    let hard: [String: SkillMeta]
//
//    static func load(softURL: URL, hardURL: URL) throws -> SkillsRegistry {
//        let decoder = JSONDecoder()
//        let softArr = try decoder.decode([SkillMeta].self, from: Data(contentsOf: softURL))
//        let hardArr = try decoder.decode([SkillMeta].self, from: Data(contentsOf: hardURL))
//        return SkillsRegistry(
//            soft: Dictionary(uniqueKeysWithValues: softArr.map { ($0.id, $0) }),
//            hard: Dictionary(uniqueKeysWithValues: hardArr.map { ($0.id, $0) })
//        )
//    }
//}
