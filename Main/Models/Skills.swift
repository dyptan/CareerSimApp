//
//  Language.swift
//  CareersApp
//
//  Created by Ivan Dyptan on 26.10.25.
//  Copyright © 2025 Apple. All rights reserved.
//


enum Language: String, Codable, Hashable, CaseIterable, Identifiable {
    case swift = "swift"
    case C = "C"
    case python = "python"
    case java = "java"
    case english = "english"
    case german = "german"
    // Keep rawValue stable but fix the case name spelling for code use
    case ukrainian = "ukraininan"
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .swift: return "🦅"   // Swift bird
        case .C: return "💾"       // Classic disk for C
        case .python: return "🐍"  // Python snake
        case .java: return "☕️"    // Coffee cup
        case .english: return "🇬🇧" // UK flag
        case .german: return "🇩🇪"  // Germany flag
        case .ukrainian: return "🇺🇦" // Ukraine flag (note: rawValue kept as "ukraininan")
        }
    }
}

enum PortfolioItem: String, Codable, Hashable, CaseIterable, Identifiable {
    case app, website, game, library, paper, presentation
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .website: return "🌐"
        case .game: return "🎮"
        case .library: return "📚"
        case .paper: return "📄"
        case .presentation: return "📊"
        }
    }
}

enum Certification: String, Codable, Hashable, CaseIterable, Identifiable{
    case aws, azure, google, scrum, security
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .aws: return "☁️"      // Cloud
        case .azure: return "🌥️"    // Sun behind cloud
        case .google: return "🔎"    // Magnifying glass
        case .scrum: return "🏉"     // Rugby football
        case .security: return "🔒"  // Lock
        }
    }
}

enum Software: String, Codable, Hashable, CaseIterable, Identifiable {
    case macOS, linux, unity, photoshop, blender, excel
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .macOS: return "🍏"
        case .linux: return "🐧"
        case .unity: return "🕹️"
        case .photoshop: return "🖌️"
        case .blender: return "🎨"
        case .excel: return "📊"
        }
    }
}

enum License: String, Codable, Hashable, CaseIterable, Identifiable {
    case drivers, pilot, nurse
    var id: String { rawValue }
}

struct HardSkills: Codable, Hashable {
    var languages = Set(Language.allCases)
    var portfolioItems = Set(PortfolioItem.allCases)
    var certifications = Set(Certification.allCases)
    var software = Set(Software.allCases)
    var licenses = Set(License.allCases)
}

struct SoftSkills: Codable, Hashable {
    var analyticalReasoning: Int
    var creativeExpression: Int
    var socialCommunication: Int
    var teamLeadership: Int
    var influenceAndNetworking: Int
    var riskTolerance: Int
    var spatialThinking: Int
    var attentionToDetail: Int
    var resilienceCognitive: Int
    var mechanicalOperation: Int
    var physicalAbility: Int
    var resiliencePhysical: Int
    var outdoorOrientation: Int
    // NEW: Entrepreneurship-related
    var opportunityRecognition: Int

    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String)] = [
        (\.analyticalReasoning, "Analytical Reasoning", "🧠"),
        (\.creativeExpression, "Creative Expression", "🎨"),
        (\.socialCommunication, "Social Communication", "💬"),
        (\.teamLeadership, "Team Leadership", "👥"),
        (\.influenceAndNetworking, "Influence & Networking", "🤝"),
        (\.riskTolerance, "Risk Tolerance", "🎲"),
        (\.spatialThinking, "Spatial Thinking", "🧭"),
        (\.attentionToDetail, "Attention to Detail", "🔎"),
        (\.mechanicalOperation, "Mechanical Operation", "🛠️"),
        (\.physicalAbility, "Physical Ability", "💪"),
        (\.resilienceCognitive, "Cognitive Resilience", "🧩"),
        (\.resiliencePhysical, "Physical Resilience", "🛡️"),
        (\.outdoorOrientation, "Outdoor Orientation", "🌲"),
        // NEW: display in UI
        (\.opportunityRecognition, "Opportunity Recognition", "🔭")
    ]
}

