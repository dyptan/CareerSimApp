import Foundation

enum License: String, CaseIterable, Codable, Hashable, Identifiable {
    case drivers = "Driver's License"
    case cdl = "CDL"
    case pilot = "Pilot"
    case commercialPilot = "Commercial Pilot"
    case nurse = "Nurse License"
    case electrician = "Electrician License"
    case plumber = "Plumber License"
    case bar = "Bar Admission"
    case professionalEngineer = "Professional Engineer"
    case architect = "Architect Licence"
    case pesticideApplicator = "Pesticide Applicator"
    case securityGuard = "Security Guard Licence"
    case masterElectrician = "Master Electrician License"
    case masterPlumber = "Master Plumber License"
    case airlineTransportPilot = "ATP"

    var id: String { rawValue }

    var friendlyName: String {
        switch self {
        case .drivers: return "Driver’s License"
        case .cdl: return "Commercial Driver’s License"
        case .pilot: return "Private Pilot License"
        case .commercialPilot: return "Commercial Pilot License"
        case .nurse: return "Nursing License"
        case .electrician: return "Electrician License"
        case .plumber: return "Plumber License"
        case .bar: return "Bar Admission (Lawyer)"
        case .professionalEngineer: return "Professional Engineer (PE)"
        case .architect: return "Architect Licence"
        case .pesticideApplicator: return "Pesticide Applicator Licence"
        case .securityGuard: return "Security Guard Licence"
        case .masterElectrician: return "Master Electrician License"
        case .masterPlumber: return "Master Plumber License"
        case .airlineTransportPilot: return "Airline Transport Pilot (ATP)"
        }
    }

    /// Plain-language explanation of the licence, for the in-game info popover.
    var description: String {
        switch self {
        case .drivers: return "Standard car licence. Needed for most jobs that involve any driving."
        case .cdl: return "Commercial Driver’s Licence — required to drive trucks, buses, and large delivery vehicles for paid work."
        case .pilot: return "Private pilot licence — lets you fly small planes for fun, but not for paid work."
        case .commercialPilot: return "Lets you fly planes for paid work — required to be hired by airlines and freight carriers."
        case .nurse: return "Government licence to work as a nurse. Earned after passing a national exam following a nursing degree."
        case .electrician: return "Government licence to wire buildings safely. Earned after an apprenticeship and an exam."
        case .plumber: return "Government licence to install and repair pipes, drains, and water systems."
        case .bar: return "Bar admission — the state-by-state exam and ethics review you must pass after law school before you can practise as a lawyer in court."
        case .professionalEngineer: return "Professional Engineer (PE) — state licence required to sign off on engineering plans for buildings, bridges, and public works. Needed for senior civil, mechanical, and electrical engineering roles."
        case .architect: return "State licence required to call yourself an Architect and stamp building plans. Earned after a degree, multi-year internship, and a national exam (NCARB)."
        case .pesticideApplicator: return "Government permit to apply restricted-use pesticides on farms or commercial landscapes. Required for many farming, landscaping, and pest-control jobs."
        case .securityGuard: return "State licence required to work as an unarmed security guard. Covers law, ethics, and basic emergency response."
        case .masterElectrician: return "The senior electrician licence. Earned after years as a licensed journeyman, it lets you pull permits, run jobs, and supervise apprentices — required to become a Master Electrician."
        case .masterPlumber: return "The senior plumbing licence. Earned after journeyman experience, it lets you design systems, pull permits, and lead a crew — required to become a Master Plumber."
        case .airlineTransportPilot: return "The highest-level pilot certificate. Required to serve as captain (pilot-in-command) of a commercial airliner."
        }
    }

    var pictogram: String {
        switch self {
        case .drivers: return "🚗"
        case .cdl: return "🚚"
        case .pilot: return "🛩️"
        case .commercialPilot: return "✈️"
        case .nurse: return "🩺"
        case .electrician: return "⚡️"
        case .plumber: return "🔧"
        case .bar: return "⚖️"
        case .professionalEngineer: return "🏗️"
        case .architect: return "📐"
        case .pesticideApplicator: return "🌱"
        case .securityGuard: return "🛡️"
        case .masterElectrician: return "⚡️"
        case .masterPlumber: return "🔧"
        case .airlineTransportPilot: return "✈️"
        }
    }

    var costForLicense: Int {
        switch self {
        case .drivers:
            // Driving school package + DMV fees + written/road test
            return 1200
        case .cdl:
            // CDL training program + exam fees
            return 4500
        case .pilot:
            // PPL: ground school + flight hours + checkride (very rough lower bound)
            return 12000
        case .commercialPilot:
            // Additional hours + checkride (very rough, incremental)
            return 20000
        case .nurse:
            // Licensing process costs; education is separate
            return 800
        case .electrician:
            // Course + exam + license application (excl. apprenticeship wages)
            return 1500
        case .plumber:
            // Course + exam + license application
            return 1500
        case .bar:
            // Bar exam + bar prep course (school is separate)
            return 5000
        case .professionalEngineer:
            // FE + PE exam fees + state licensing
            return 1500
        case .architect:
            // ARE multi-division exam + state licensing
            return 2500
        case .pesticideApplicator:
            // State certification course + exam
            return 300
        case .securityGuard:
            // Pre-licensing course + state guard card
            return 250
        case .masterElectrician:
            // Master exam + licensing (after journeyman experience)
            return 2500
        case .masterPlumber:
            // Master exam + licensing
            return 2500
        case .airlineTransportPilot:
            // ATP: extra hours, type rating, and checkride (rough incremental)
            return 30000
        }
    }

    
    /// Life stages in which this licence is offered. Driver's and private pilot are
    /// reachable at 16/17 so they surface in the teen sheet; everything else
    /// requires age 18+ and only appears from young adulthood onward.
    var stages: Set<LifeStage> {
        switch self {
        case .drivers, .pilot:
            return [.teen, .youngAdult, .adult]
        default:
            return [.youngAdult, .adult]
        }
    }

    /// Licences that must already be held before this one can be pursued — the
    /// licence prerequisite chain (a CDL needs a Driver's License first, an ATP
    /// builds on a Commercial Pilot License, and so on). This is the declarative
    /// source of truth: `licenseRequirements` enforces it at runtime and
    /// `CareerGraph` reads it to validate the chain stays acyclic.
    var prerequisiteLicenses: [License] {
        switch self {
        case .cdl: return [.drivers]
        case .commercialPilot: return [.pilot]
        case .masterElectrician: return [.electrician]
        case .masterPlumber: return [.plumber]
        case .airlineTransportPilot: return [.commercialPilot]
        default: return []
        }
    }

    // Minimum EQF level (education) required before pursuing this license
    var minEQF: Int {
        switch self {
        case .bar:                                      return 7  // requires a Doctor of Law (J.D.)
        case .architect, .professionalEngineer:         return 5  // requires a Bachelor in the field
        case .airlineTransportPilot:                    return 5  // builds on a commercial pilot career
        case .nurse, .electrician, .plumber,
             .masterElectrician, .masterPlumber:        return 4  // vocational trade training required
        default:                                        return 0
        }
    }

    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .drivers:
            // Basic road navigation + attention to traffic rules
            return [
                (\.spacialNavigationAndOrientation, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .cdl:
            // Large vehicle manoeuvring, HOS compliance, long-haul demands
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
                (\.resilienceAndEndurance, 2),
                (\.timeManagementAndPlanning, 2),
            ]
        case .pilot:
            // 3-D airspace navigation, pre-flight checklists, in-flight decisions
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .commercialPilot:
            // Higher standards than PPL; PIC authority and crew management added
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
            ]
        case .nurse:
            // 12-hour shifts, physical patient care, high-stakes clinical decisions
            return [
                (\.communicationAndNetworking, 3),
                (\.empathyAndInterpersonalCare, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.resilienceAndEndurance, 3),
            ]
        case .electrician:
            // Circuit analysis, blueprint reading — wrong wiring can cause fire or death
            return [
                (\.tinkeringAndFingerPrecision, 4),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .plumber:
            // Pipe routing through structures, outdoor/crawlspace work, physical demands
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.spacialNavigationAndOrientation, 2),
                (\.resilienceAndEndurance, 2),
                (\.outdoorAndWeatherResilience, 1),
            ]
        case .bar:
            // Bar exam: enormous study load + courtroom-grade analysis and communication
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.communicationAndNetworking, 4),
                (\.selfDisciplineAndPerseverance, 4),
                (\.presentationAndStorytelling, 3),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .professionalEngineer:
            // PE exam: deep technical mastery; signed plans must be defensible in court
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.selfDisciplineAndPerseverance, 3),
            ]
        case .architect:
            // ARE: design judgement combined with code, structural, and project knowledge
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
                (\.selfDisciplineAndPerseverance, 2),
            ]
        case .pesticideApplicator:
            // Pesticide handling: chemical safety, label law, careful dosing
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.outdoorAndWeatherResilience, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .securityGuard:
            // De-escalation, calm presence, clear reporting
            return [
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.resilienceAndEndurance, 2),
            ]
        case .masterElectrician:
            // Beyond journeyman skill: running jobs and supervising apprentices
            return [
                (\.tinkeringAndFingerPrecision, 4),
                (\.carefulnessAndAttentionToDetail, 4),
                (\.analyticalReasoningAndProblemSolving, 3),
            ]
        case .masterPlumber:
            // Beyond journeyman skill: system design and crew leadership
            return [
                (\.tinkeringAndFingerPrecision, 4),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .airlineTransportPilot:
            // Pilot-in-command of an airliner: the highest bar in aviation
            return [
                (\.spacialNavigationAndOrientation, 4),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 4),
                (\.analyticalReasoningAndProblemSolving, 3),
            ]
        }
    }

    func licenseRequirements(_ player: Player) -> TrainingRequirementResult {
        let age = player.age

        // Age checks
        switch self {
        case .drivers:
            if age < 16 { return .blocked(reason: "Requires age 16+") }
        case .cdl, .nurse, .electrician, .plumber,
             .pesticideApplicator, .securityGuard,
             .masterElectrician, .masterPlumber:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .pilot:
            if age < 17 { return .blocked(reason: "Requires age 17+") }
        case .commercialPilot, .bar, .professionalEngineer, .architect,
             .airlineTransportPilot:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        }

        // Prerequisite license checks (declared in `prerequisiteLicenses`).
        for prereq in prerequisiteLicenses {
            guard player.hardSkills.licenses.contains(prereq) else {
                return .blocked(reason: "Requires \(prereq.friendlyName) first")
            }
        }

        // Education prerequisite
        let highestEQF = player.degrees.map(\.eqf).max() ?? 0
        if highestEQF < minEQF {
            let label = Education.Requirements(minEQF: minEQF).educationLabel()
            return .blocked(reason: "Requires \(label)")
        }

        // Soft skill checks
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }

        return .ok(cost: costForLicense)
    }

}
