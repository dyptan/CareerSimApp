import Foundation

enum Software: String, CaseIterable, Codable, Hashable, Identifiable {
    case macOS = "macOS"
    case linux = "Linux"
    case excel = "Excel"
    case unity = "Unity"
    case photoshop = "Photoshop"
    case blender = "Blender"

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .macOS: return "🍎"
        case .linux: return "🐧"
        case .excel: return "📊"
        case .unity: return "🕹️"
        case .photoshop: return "🖌️"
        case .blender: return "🌀"
        }
    }
}
