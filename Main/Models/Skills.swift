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
    // Existing
    case aws, azure, google, scrum, security
    // Skilled trades
    case cwi           // Certified Welding Inspector
    case epa608        // EPA 608 (HVAC)
    case nate          // NATE (HVAC)
    case faaAMP        // FAA A&P (Aircraft Mechanic)
    // Healthcare support
    case cna           // Certified Nursing Assistant
    case dentalAssistant
    case medicalAssistant
    case pharmacyTech
    // Business and finance
    case cfp           // Certified Financial Planner
    case series65
    // Transportation and logistics
    case flightAttendantCert
    
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .aws: return "☁️"
        case .azure: return "🌥️"
        case .google: return "🔎"
        case .scrum: return "🏉"
        case .security: return "🔒"
        case .cwi: return "🧪"
        case .epa608: return "🌡️"
        case .nate: return "❄️"
        case .faaAMP: return "✈️"
        case .cna: return "🩺"
        case .dentalAssistant: return "🦷"
        case .medicalAssistant: return "🏥"
        case .pharmacyTech: return "💊"
        case .cfp: return "📈"
        case .series65: return "💹"
        case .flightAttendantCert: return "🛫"
        }
    }
    
    // Kid-friendly display names
    var friendlyName: String {
        switch self {
        case .aws: return "AWS Cloud Badge \(pictogram)"
        case .azure: return "Azure Cloud Badge \(pictogram)"
        case .google: return "Google Tech Badge \(pictogram)"
        case .scrum: return "Teamwork (Scrum) Badge \(pictogram)"
        case .security: return "Online Safety Badge \(pictogram)"
        case .cwi: return "Welding Inspector (CWI) \(pictogram)"
        case .epa608: return "HVAC Clean Air (EPA 608) \(pictogram)"
        case .nate: return "HVAC Pro (NATE) \(pictogram)"
        case .faaAMP: return "Airplane Fixer (FAA A&P) \(pictogram)"
        case .cna: return "Care Helper (CNA) \(pictogram)"
        case .dentalAssistant: return "Tooth Helper (Dental Assistant) \(pictogram)"
        case .medicalAssistant: return "Clinic Helper (Medical Assistant) \(pictogram)"
        case .pharmacyTech: return "Medicine Helper (Pharmacy Tech) \(pictogram)"
        case .cfp: return "Money Planner (CFP) \(pictogram)"
        case .series65: return "Investing Helper (Series 65) \(pictogram)"
        case .flightAttendantCert: return "Flight Helper (Attendant Cert) \(pictogram)"
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
    // Existing
    case drivers, pilot, nurse
    // Skilled trades
    case electrician
    case plumber
    // Transportation and logistics
    case cdl
    case commercialPilot
    // Business & finance
    case realEstateAgent
    case insuranceAgent
    
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .drivers: return "🚗"
        case .pilot: return "✈️"
        case .nurse: return "🩺"
        case .electrician: return "🔌"
        case .plumber: return "🔧"
        case .cdl: return "🚚"
        case .commercialPilot: return "🛫"
        case .realEstateAgent: return "🏠"
        case .insuranceAgent: return "🛡️"
        }
    }
    
    var friendlyName: String {
        switch self {
        case .drivers: return "Driver’s License \(pictogram)"
        case .pilot: return "Pilot License \(pictogram)"
        case .nurse: return "Nurse License \(pictogram)"
        case .electrician: return "Electrician License \(pictogram)"
        case .plumber: return "Plumber License \(pictogram)"
        case .cdl: return "Commercial Driver’s License \(pictogram)"
        case .commercialPilot: return "Commercial Pilot License \(pictogram)"
        case .realEstateAgent: return "Real Estate Agent License \(pictogram)"
        case .insuranceAgent: return "Insurance Agent License \(pictogram)"
        }
    }
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

