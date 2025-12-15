import Foundation

enum Certification: String, CaseIterable, Codable, Hashable, Identifiable {
    case aws = "AWS"
    case azure = "Azure"
    case google = "Google"
    case scrum = "Scrum"
    case security = "Security"
    case cwi = "CWI"
    case epa608 = "EPA608"
    case nate = "NATE"
    case faaAMP = "FAA A&P"
    case cna = "CNA"
    case dentalAssistant = "Dental Assistant"
    case medicalAssistant = "Medical Assistant"
    case pharmacyTech = "Pharmacy Tech"
    case cfp = "CFP"
    case series65 = "Series 65"
    case flightAttendantCert = "Flight Attendant"

    var id: String { rawValue }

    var friendlyName: String {
        switch self {
        case .aws: return "AWS Certification"
        case .azure: return "Azure Certification"
        case .google: return "Google Cloud Certification"
        case .scrum: return "Scrum Master"
        case .security: return "Security Awareness"
        case .cwi: return "Certified Welding Inspector"
        case .epa608: return "EPA 608"
        case .nate: return "NATE Certification"
        case .faaAMP: return "FAA A&P"
        case .cna: return "Certified Nursing Assistant"
        case .dentalAssistant: return "Dental Assistant"
        case .medicalAssistant: return "Medical Assistant"
        case .pharmacyTech: return "Pharmacy Technician"
        case .cfp: return "Certified Financial Planner"
        case .series65: return "Series 65"
        case .flightAttendantCert: return "Flight Attendant Certificate"
        }
    }

    var pictogram: String {
        switch self {
        case .aws, .azure, .google: return "☁️"
        case .scrum: return "📈"
        case .security: return "🔐"
        case .cwi: return "⚙️"
        case .epa608: return "🌬️"
        case .nate: return "🧰"
        case .faaAMP: return "✈️"
        case .cna: return "🏥"
        case .dentalAssistant: return "🦷"
        case .medicalAssistant: return "🩺"
        case .pharmacyTech: return "💊"
        case .cfp: return "💼"
        case .series65: return "📜"
        case .flightAttendantCert: return "🧳"
        }
    }
    
    var costForCertification: Int {
        switch self {
        case .aws: return 350
        case .azure: return 350
        case .google: return 300
        case .scrum: return 600
        case .security: return 250
        case .cwi: return 3000
        case .epa608: return 200
        case .nate: return 450
        case .faaAMP: return 6000
        case .cna: return 1500
        case .dentalAssistant: return 2500
        case .medicalAssistant: return 3500
        case .pharmacyTech: return 1200
        case .cfp: return 7000
        case .series65: return 500
        case .flightAttendantCert: return 1000
        }
    }

    // MARK: - Requirements profile for UI rendering (like Job requirements)
    struct RequirementsProfile: Hashable {
        var analyticalReasoningAndProblemSolving: Int = 0
        var creativityAndInsightfulThinking: Int = 0
        var communicationAndNetworking: Int = 0
        var leadershipAndInfluence: Int = 0
        var courageAndRiskTolerance: Int = 0
        var spacialNavigation: Int = 0
        var carefulnessAndAttentionToDetail: Int = 0
        var perseveranceAndGrit: Int = 0
        var tinkeringAndFingerPrecision: Int = 0
        var physicalStrength: Int = 0
        var coordinationAndBalance: Int = 0
        var resilienceAndEndurance: Int = 0
    }

    // Builds the threshold profile used by the UI, and evaluates if player meets it.
    func requirementsProfile(for player: Player) -> (profile: RequirementsProfile, meetsAll: Bool, cost: Int, message: String?) {
        var r = RequirementsProfile()


        switch self {
        case .cna:
            r.communicationAndNetworking = 2
            r.resilienceAndEndurance = 2
            r.carefulnessAndAttentionToDetail = 2

        case .dentalAssistant:
            r.carefulnessAndAttentionToDetail = 3
            r.communicationAndNetworking = 2

        case .medicalAssistant:
            r.communicationAndNetworking = 2
            r.carefulnessAndAttentionToDetail = 3
            r.perseveranceAndGrit = 2

        case .pharmacyTech:
            r.analyticalReasoningAndProblemSolving = 2
            r.carefulnessAndAttentionToDetail = 3

        case .cwi:
            r.perseveranceAndGrit = 3
            r.carefulnessAndAttentionToDetail = 3

        case .epa608:
            r.carefulnessAndAttentionToDetail = 3
            r.analyticalReasoningAndProblemSolving = 2

        case .nate:
            r.tinkeringAndFingerPrecision = 3
            r.perseveranceAndGrit = 2

        case .faaAMP:
            r.tinkeringAndFingerPrecision = 3
            r.carefulnessAndAttentionToDetail = 3
            r.perseveranceAndGrit = 3

        case .cfp:
            r.analyticalReasoningAndProblemSolving = 3
            r.communicationAndNetworking = 2

        case .series65:
            r.analyticalReasoningAndProblemSolving = 3

        case .flightAttendantCert:
            r.communicationAndNetworking = 2
            r.resilienceAndEndurance = 3

        case .aws:
            r.analyticalReasoningAndProblemSolving = 3
        case .azure:
            r.analyticalReasoningAndProblemSolving = 3
        case .google:
            r.analyticalReasoningAndProblemSolving = 3
        case .scrum:
            r.communicationAndNetworking = 2
        case .security:
            r.analyticalReasoningAndProblemSolving = 2
            r.carefulnessAndAttentionToDetail = 2
        }

        // Evaluate meetsAll
        let s = player.softSkills
        var meets = true
        meets = meets && s.analyticalReasoningAndProblemSolving >= r.analyticalReasoningAndProblemSolving
        meets = meets && s.creativityAndInsightfulThinking >= r.creativityAndInsightfulThinking
        meets = meets && s.communicationAndNetworking >= r.communicationAndNetworking
        meets = meets && s.leadershipAndInfluence >= r.leadershipAndInfluence
        meets = meets && s.courageAndRiskTolerance >= r.courageAndRiskTolerance
        meets = meets && s.spacialNavigationAndOrientation >= r.spacialNavigation
        meets = meets && s.carefulnessAndAttentionToDetail >= r.carefulnessAndAttentionToDetail
        meets = meets && s.patienceAndPerseverance >= r.perseveranceAndGrit
        meets = meets && s.tinkeringAndFingerPrecision >= r.tinkeringAndFingerPrecision
        meets = meets && s.physicalStrengthAndEndurance >= r.physicalStrength
        meets = meets && s.coordinationAndBalance >= r.coordinationAndBalance
        meets = meets && s.physicalStrengthAndEndurance >= r.resilienceAndEndurance

        // Derive a simple first unmet message (optional)
        let message: String? = {
            if s.analyticalReasoningAndProblemSolving < r.analyticalReasoningAndProblemSolving { return "Needs more Problem Solving" }
            if s.creativityAndInsightfulThinking < r.creativityAndInsightfulThinking { return "Needs more Creativity" }
            if s.communicationAndNetworking < r.communicationAndNetworking { return "Needs better Communication" }
            if s.leadershipAndInfluence < r.leadershipAndInfluence { return "Needs more Leadership" }
            if s.courageAndRiskTolerance < r.courageAndRiskTolerance { return "Needs more Courage" }
            if s.spacialNavigationAndOrientation < r.spacialNavigation { return "Needs better Navigation" }
            if s.carefulnessAndAttentionToDetail < r.carefulnessAndAttentionToDetail { return "Needs more Carefulness" }
            if s.patienceAndPerseverance < r.perseveranceAndGrit { return "Needs more Perseverance" }
            if s.tinkeringAndFingerPrecision < r.tinkeringAndFingerPrecision { return "Needs more Tinkering" }
            if s.physicalStrengthAndEndurance < r.physicalStrength { return "Needs more Strength" }
            if s.coordinationAndBalance < r.coordinationAndBalance { return "Needs better Coordination" }
            if s.physicalStrengthAndEndurance < r.resilienceAndEndurance { return "Needs more Endurance" }
            return nil
        }()

        return (r, meets, costForCertification, message)
    }

    // Existing gating remains available for logic decisions
    func certificationRequirements(_ player: Player) -> TrainingRequirementResult {
        let s = player.softSkills


        switch self {
        case .cna:
            guard s.communicationAndNetworking >= 2 else { return .blocked(reason: "Needs better Communication") }
            guard s.physicalStrengthAndEndurance >= 2 else { return .blocked(reason: "Needs more Endurance") }
            guard s.carefulnessAndAttentionToDetail >= 2 else { return .blocked(reason: "Needs more Carefulness") }
            return .ok(cost: costForCertification)

        case .dentalAssistant:
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            guard s.communicationAndNetworking >= 2 else { return .blocked(reason: "Needs better Communication") }
            return .ok(cost: costForCertification)

        case .medicalAssistant:
            guard s.communicationAndNetworking >= 2 else { return .blocked(reason: "Needs better Communication") }
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            guard s.patienceAndPerseverance >= 2 else { return .blocked(reason: "Needs more Perseverance") }
            return .ok(cost: costForCertification)

        case .pharmacyTech:
            guard s.analyticalReasoningAndProblemSolving >= 2 else { return .blocked(reason: "Needs more Problem Solving") }
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            return .ok(cost: costForCertification)

        case .cwi:
            guard s.patienceAndPerseverance >= 3 else { return .blocked(reason: "Needs more Perseverance") }
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            return .ok(cost: costForCertification)

        case .epa608:
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            guard s.analyticalReasoningAndProblemSolving >= 2 else { return .blocked(reason: "Needs more Problem Solving") }
            return .ok(cost: costForCertification)

        case .nate:
            guard s.tinkeringAndFingerPrecision >= 3 else { return .blocked(reason: "Needs more Tinkering") }
            guard s.patienceAndPerseverance >= 2 else { return .blocked(reason: "Needs more Perseverance") }
            return .ok(cost: costForCertification)

        case .faaAMP:
            guard s.tinkeringAndFingerPrecision >= 3 else { return .blocked(reason: "Needs more Tinkering") }
            guard s.carefulnessAndAttentionToDetail >= 3 else { return .blocked(reason: "Needs more Carefulness") }
            guard s.patienceAndPerseverance >= 3 else { return .blocked(reason: "Needs more Perseverance") }
            return .ok(cost: costForCertification)

        case .cfp:
            guard s.analyticalReasoningAndProblemSolving >= 3 else { return .blocked(reason: "Needs more Problem Solving") }
            guard s.communicationAndNetworking >= 2 else { return .blocked(reason: "Needs better Communication") }
            return .ok(cost: costForCertification)

        case .series65:
            guard s.analyticalReasoningAndProblemSolving >= 3 else { return .blocked(reason: "Needs more Problem Solving") }
            return .ok(cost: costForCertification)

        case .flightAttendantCert:
            guard s.communicationAndNetworking >= 2 else { return .blocked(reason: "Needs better Communication") }
            guard s.physicalStrengthAndEndurance >= 3 else { return .blocked(reason: "Needs more Endurance") }
            return .ok(cost: costForCertification)

        case .aws, .azure, .google, .scrum, .security:
            let prof = requirementsProfile(for: player)
            guard prof.meetsAll else { return .blocked(reason: prof.message ?? "Requirements not met") }
            return .ok(cost: costForCertification)
        }
    }
}

