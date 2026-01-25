import Foundation

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
}
