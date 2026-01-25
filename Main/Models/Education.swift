// Education.swift

import Foundation

// Stage-only representation of education level
struct Level: Codable, Hashable, Identifiable {
    enum Stage: String, CaseIterable, Codable, Hashable {
        case PrimarySchool
        case MiddleSchool
        case HighSchool
        case Vocational
        case Bachelor
        case Master
        case Doctorate
    }

    var stage: Stage

    var id: String { stage.rawValue }

    // EQF mapping by stage
    var eqf: Int {
        switch stage {
        case .PrimarySchool: return 1
        case .MiddleSchool: return 2
        case .HighSchool: return 3
        case .Vocational: return 4
        case .Bachelor: return 5
        case .Master: return 6
        case .Doctorate: return 7
        }
    }

    /// Human-readable generic degree label (EU default)
    var degree: String {
        switch stage {
        case .PrimarySchool: return "Primary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Vocational Diploma"
        case .Bachelor: return "Bachelor"
        case .Master: return "Master"
        case .Doctorate: return "Doctorate"
        }
    }

    /// Human-readable generic degree label (US variant)
    var degreeUS: String {
        switch stage {
        case .PrimarySchool: return "Elementary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Trade Certificate"
        case .Bachelor: return "Bachelor’s Degree"
        case .Master: return "Master’s Degree"
        case .Doctorate: return "Doctoral Degree"
        }
    }

    /// Number of in-game years typically needed to complete this level
    func yearsToComplete() -> Int {
        switch stage {
        case .PrimarySchool: return 5
        case .MiddleSchool: return 3
        case .HighSchool: return 3
        case .Vocational: return 2
        case .Bachelor: return 3
        case .Master: return 2
        case .Doctorate: return 3
        }
    }
}

// Profiles for tertiary education
enum TertiaryProfile: String, CaseIterable, Codable, Hashable, Identifiable {
    case business
    case engineering
    case health
    case arts
    case science
    case education
    case technology
    case sports
    case agriculture
    case humanities
    case law
    case design
    case service

    var id: String { rawValue }

    /// Human-readable description for each profile
    var description: String {
        switch self {
        case .business: return "Business, management, and entrepreneurship."
        case .engineering:
            return "Design, build, and solve technical challenges."
        case .health: return "Medical, care, and wellbeing professions."
        case .arts: return "Visual, performing, and creative arts."
        case .science: return "Research, discovery, and experiments."
        case .education: return "Teaching and supporting learners."
        case .technology: return "Computers, programming, and digital."
        case .sports: return "Physical activity, coaching, and competition."
        case .agriculture: return "Farming, food production, and animals."
        case .humanities: return "Culture, history, and society."
        case .law: return "Legal, justice, and social order."
        case .design: return "Making things functional and beautiful."
        case .service: return "Help, care, and support roles."
        }
    }

    /// Short kid-friendly summary (very brief)
    var shortKidSummary: String {
        switch self {
        case .business: return "Learn how to start, run, and grow a company."
        case .engineering: return "Build cool things and solve real problems."
        case .health: return "Help people feel better and stay healthy."
        case .arts: return "Create music, drawings, and performances."
        case .science: return "Explore how the world works with experiments."
        case .education: return "Teach and guide students to learn."
        case .technology: return "Make apps, games, and smart machines."
        case .sports: return "Train bodies and minds to perform their best."
        case .agriculture: return "Grow food and care for plants and animals."
        case .humanities: return "Study people, cultures, and history."
        case .law: return "Learn rules, rights, and justice systems to help people follow the law."
        case .design: return "Make things useful and beautiful."
        case .service: return "Help others with important everyday tasks."
        }
    }

    /// What the degree means (plain language)
    var degreeMeaning: String {
        switch self {
        case .business:
            return "You learn how money, teams, and products work together to make a business succeed."
        case .engineering:
            return "You learn math, science, and design to make machines, bridges, and technologies work."
        case .health:
            return "You learn how the body works and how to care for people in clinics and hospitals."
        case .arts:
            return "You practice creative skills like drawing, music, acting, or cooking to express ideas."
        case .science:
            return "You learn to ask questions, test ideas, and discover new knowledge about nature and the universe."
        case .education:
            return "You learn how people learn, and how to teach different subjects to students."
        case .technology:
            return "You learn coding, systems, and security to build software and manage data."
        case .sports:
            return "You learn about movement, training, and health to improve athletic performance."
        case .agriculture:
            return "You learn how to grow crops, care for animals, and manage farms sustainably."
        case .humanities:
            return "You study language, culture, and history to understand people and societies."
        case .law:
            return "You learn rules, rights, and justice systems to help people follow the law."
        case .design:
            return "You learn to plan how things look and work so they’re easy and fun to use."
        case .service:
            return "You learn practical skills to support people in daily life and at work."
        }
    }

    var helpfulJobs: String {
        switch self {
        case .business:
            return "Manager, marketer, accountant, entrepreneur"
        case .engineering:
            return "Civil, mechanical, electrical, robotics engineer"
        case .health:
            return "Nurse, therapist, lab tech, clinic assistant"
        case .arts:
            return "Designer, musician, chef, actor"
        case .science:
            return "Researcher, lab technician, data analyst"
        case .education:
            return "Teacher, tutor, school counselor"
        case .technology:
            return "Developer, tester, cybersecurity, data engineer"
        case .sports:
            return "Coach, trainer, sports scientist, physiologist"
        case .agriculture:
            return "Farmer, agronomist, animal caretaker"
        case .humanities:
            return "Historian, writer, museum guide, analyst"
        case .law:
            return "Paralegal, legal assistant, compliance officer"
        case .design:
            return "Graphic, UX/UI, fashion, interior designer"
        case .service:
            return "Hospitality worker, customer support, operations"
        }
    }

    var isSTEM: Bool {
        switch self {
        case .engineering, .science, .technology:
            return true
        default:
            return false
        }
    }

    var allowsVocational: Bool {
        switch self {
        case .engineering, .technology, .health, .agriculture, .design, .service, .sports:
            return true
        case .business, .arts, .science, .education, .humanities, .law:
            return false
        }
    }
}

struct Education: Codable, Hashable, Identifiable {
    var level: Level.Stage
    var profile: TertiaryProfile?  // nil for early education

    var id: String {
        if let p = profile {
            return "\(level.rawValue)-\(p.rawValue)"
        } else {
            return level.rawValue
        }
    }

    init(_ level: Level.Stage) {
        self.level = level
        self.profile = nil
    }

    init(_ level: Level.Stage, profile: TertiaryProfile) {
        self.level = level
        self.profile = profile
    }

    var eqf: Int { Level(stage: level).eqf }
    var yearsToComplete: Int { Level(stage: level).yearsToComplete() }

    // Updated Requirements struct to match the Job model
    struct Requirements: Codable, Hashable {
        var minEQF: Int = 0

        // Soft skills thresholds matching the Job model
        var analyticalReasoningAndProblemSolving: Int = 0
        var creativityAndInsightfulThinking: Int = 0
        var communicationAndNetworking: Int = 0
        var leadershipAndInfluence: Int = 0
        var courageAndRiskTolerance: Int = 0
        var spacialNavigationAndOrientation: Int = 0
        var carefulnessAndAttentionToDetail: Int = 0
        var patienceAndPerseverance: Int = 0
        var tinkeringAndFingerPrecision: Int = 0
        var physicalStrengthAndEndurance: Int = 0
        var coordinationAndBalance: Int = 0
        var stressResistanceAndEmotionalRegulation: Int = 0
        var outdoorAndWeatherResilience: Int = 0
        var collaborationAndTeamwork: Int = 0
        var timeManagementAndPlanning: Int = 0
        var selfDisciplineAndStudyHabits: Int = 0
        var adaptabilityAndLearningAgility: Int = 0
        var presentationAndStorytelling: Int = 0

        init(minEQF: Int = 0) {
            self.minEQF = minEQF
        }

        func educationLabel() -> String {
            switch minEQF {
            case ..<1: return "Primary school"
            case 1: return "Primary school"
            case 2: return "Middle school"
            case 3: return "High school"
            case 4: return "College / Vocational"
            case 5: return "University — Bachelor's"
            case 6: return "University — Master's"
            case 7: return "Doctorate"
            default: return "Doctorate+"
            }
        }
    }

    var requirements: Requirements {
        guard let p = profile else { return Requirements() }

        var base = Education.baseRequirements(for: p)

        // Escalate by level, enforce minimums, and clamp to 0...5
        switch level {
        case .Vocational:
            base.minEQF = 3
            return Education.clamped(base)
        case .Bachelor:
            var r = Education.elevated(base, by: 1)
            r.minEQF = 3
            r = Education.enforceMinimums(r, for: .Bachelor, profile: p)
            return Education.clamped(r)
        case .Master:
            var r = Education.elevated(base, by: 2)
            r.minEQF = 5
            r = Education.enforceMinimums(r, for: .Master, profile: p)
            return Education.clamped(r)
        case .Doctorate:
            var r = Education.elevated(base, by: 3)
            r.minEQF = 6
            r = Education.enforceMinimums(r, for: .Doctorate, profile: p)
            return Education.clamped(r)
        default:
            return Requirements()
        }
    }

    func meetsRequirements(player: Player) -> Bool {
        let p = player.softSkills
        let highestEQF = player.degrees.last?.eqf ?? 0
        let r = requirements

        guard highestEQF >= r.minEQF else { return false }
        guard p.analyticalReasoningAndProblemSolving >= r.analyticalReasoningAndProblemSolving else { return false }
        guard p.creativityAndInsightfulThinking >= r.creativityAndInsightfulThinking else { return false }
        guard p.communicationAndNetworking >= r.communicationAndNetworking else { return false }
        guard p.leadershipAndInfluence >= r.leadershipAndInfluence else { return false }
        guard p.courageAndRiskTolerance >= r.courageAndRiskTolerance else { return false }
        guard p.spacialNavigationAndOrientation >= r.spacialNavigationAndOrientation else { return false }
        guard p.carefulnessAndAttentionToDetail >= r.carefulnessAndAttentionToDetail else { return false }
        guard p.patienceAndPerseverance >= r.patienceAndPerseverance else { return false }
        guard p.tinkeringAndFingerPrecision >= r.tinkeringAndFingerPrecision else { return false }
        guard p.physicalStrengthAndEndurance >= r.physicalStrengthAndEndurance else { return false }
        guard p.coordinationAndBalance >= r.coordinationAndBalance else { return false }
        guard p.stressResistanceAndEmotionalRegulation >= r.stressResistanceAndEmotionalRegulation else { return false }
        guard p.outdoorAndWeatherResilience >= r.outdoorAndWeatherResilience else { return false }
        guard p.collaborationAndTeamwork >= r.collaborationAndTeamwork else { return false }
        guard p.timeManagementAndPlanning >= r.timeManagementAndPlanning else { return false }
        guard p.selfDisciplineAndStudyHabits >= r.selfDisciplineAndStudyHabits else { return false }
        guard p.adaptabilityAndLearningAgility >= r.adaptabilityAndLearningAgility else { return false }
        guard p.presentationAndStorytelling >= r.presentationAndStorytelling else { return false }

        return true
    }

    var degreeName: String {
        switch (level, profile) {
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Vocational Diploma in \(title)"
        case (.Vocational, _):
            return "Vocational Diploma"
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Engineering"
            case .health: return "Bachelor of Health Sciences"
            case .arts: return "Bachelor of Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology: return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Agriculture"
            case .humanities: return "Bachelor of Arts in Humanities"
            case .law: return "Bachelor of Laws"
            case .design: return "Bachelor of Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Sports Science"
            }
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Engineering"
            case .health: return "Master of Health Sciences"
            case .arts: return "Master of Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology: return "Master of Science in Information Technology"
            case .agriculture: return "Master of Agriculture"
            case .humanities: return "Master of Philosophy in Humanities"
            case .law: return "Master of Laws"
            case .design: return "Master of Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Sports Science"
            }
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology: return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .humanities: return "Doctor of Philosophy in Humanities"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Sports Science"
            }
        default:
            return Level(stage: level).degree
        }
    }

    var degreeUS: String {
        switch (level, profile) {
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Associate of Applied Science in \(title)"
        case (.Vocational, _):
            return "Trade Certificate"
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Science in Engineering"
            case .health: return "Bachelor of Science in Health Sciences"
            case .arts: return "Bachelor of Arts in Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology: return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Science in Agriculture"
            case .humanities: return "Bachelor of Arts in Humanities"
            case .law: return "Bachelor of Arts in Law"
            case .design: return "Bachelor of Arts in Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Kinesiology"
            }
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Science in Engineering"
            case .health: return "Master of Science in Health Sciences"
            case .arts: return "Master of Arts in Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology: return "Master of Science in Information Technology"
            case .agriculture: return "Master of Science in Agriculture"
            case .humanities: return "Master of Arts in Humanities"
            case .law: return "Master of Laws"
            case .design: return "Master of Arts in Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Kinesiology"
            }
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology: return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .humanities: return "Doctor of Philosophy in Humanities"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Kinesiology"
            }
        default:
            return Level(stage: level).degreeUS
        }
    }
    
    // MARK: - Requirements scaffolding to scale difficulty

    private static func baseRequirements(for profile: TertiaryProfile) -> Requirements {
        var r = Requirements(minEQF: 3)

        // Core values doubled (capped at 5) + a few non-essential adds
        switch profile {
        case .technology:
            r.analyticalReasoningAndProblemSolving = 4
            r.carefulnessAndAttentionToDetail = 4
            r.patienceAndPerseverance = 4
            r.selfDisciplineAndStudyHabits = 4
            r.tinkeringAndFingerPrecision = 2
            r.timeManagementAndPlanning = 2
            r.collaborationAndTeamwork = 2
            // non-essential
            r.presentationAndStorytelling = 1
            r.adaptabilityAndLearningAgility = 1
            r.communicationAndNetworking = 1

        case .engineering:
            r.analyticalReasoningAndProblemSolving = 4
            r.spacialNavigationAndOrientation = 4
            r.patienceAndPerseverance = 4
            r.carefulnessAndAttentionToDetail = 2
            r.tinkeringAndFingerPrecision = 2
            r.timeManagementAndPlanning = 2
            r.collaborationAndTeamwork = 2
            // non-essential
            r.presentationAndStorytelling = 1
            r.selfDisciplineAndStudyHabits = 1

        case .science:
            r.analyticalReasoningAndProblemSolving = 4
            r.patienceAndPerseverance = 4
            r.selfDisciplineAndStudyHabits = 4
            r.timeManagementAndPlanning = 2
            r.presentationAndStorytelling = 2
            // non-essential
            r.carefulnessAndAttentionToDetail = 1
            r.collaborationAndTeamwork = 1

        case .arts:
            r.creativityAndInsightfulThinking = 5
            r.presentationAndStorytelling = 4
            r.carefulnessAndAttentionToDetail = 2
            r.patienceAndPerseverance = 2
            r.communicationAndNetworking = 2
            // non-essential
            r.adaptabilityAndLearningAgility = 1
            r.selfDisciplineAndStudyHabits = 1

        case .design:
            r.creativityAndInsightfulThinking = 5
            r.carefulnessAndAttentionToDetail = 4
            r.presentationAndStorytelling = 4
            r.spacialNavigationAndOrientation = 2
            // non-essential
            r.analyticalReasoningAndProblemSolving = 1
            r.collaborationAndTeamwork = 1
            r.timeManagementAndPlanning = 1

        case .business:
            r.communicationAndNetworking = 4
            r.leadershipAndInfluence = 4
            r.analyticalReasoningAndProblemSolving = 2
            r.timeManagementAndPlanning = 4
            r.presentationAndStorytelling = 4
            r.collaborationAndTeamwork = 2
            r.courageAndRiskTolerance = 2
            // non-essential
            r.adaptabilityAndLearningAgility = 1
            r.patienceAndPerseverance = 1
            r.selfDisciplineAndStudyHabits = 1

        case .education:
            r.communicationAndNetworking = 4
            r.stressResistanceAndEmotionalRegulation = 4
            r.presentationAndStorytelling = 4
            r.patienceAndPerseverance = 4
            r.timeManagementAndPlanning = 2
            // non-essential
            r.collaborationAndTeamwork = 1
            r.adaptabilityAndLearningAgility = 1
            r.selfDisciplineAndStudyHabits = 1

        case .health:
            r.communicationAndNetworking = 4
            r.carefulnessAndAttentionToDetail = 4
            r.physicalStrengthAndEndurance = 4
            r.stressResistanceAndEmotionalRegulation = 4
            r.patienceAndPerseverance = 2
            // non-essential
            r.coordinationAndBalance = 2
            r.timeManagementAndPlanning = 1
            r.collaborationAndTeamwork = 1

        case .sports:
            r.physicalStrengthAndEndurance = 4
            r.coordinationAndBalance = 4
            r.collaborationAndTeamwork = 4
            r.selfDisciplineAndStudyHabits = 4
            // non-essential
            r.patienceAndPerseverance = 2
            r.courageAndRiskTolerance = 1
            r.timeManagementAndPlanning = 1

        case .agriculture:
            r.patienceAndPerseverance = 4
            r.physicalStrengthAndEndurance = 4
            r.outdoorAndWeatherResilience = 4
            r.timeManagementAndPlanning = 2
            // non-essential
            r.spacialNavigationAndOrientation = 1
            r.carefulnessAndAttentionToDetail = 1
            r.collaborationAndTeamwork = 1

        case .humanities:
            r.communicationAndNetworking = 4
            r.patienceAndPerseverance = 4
            r.presentationAndStorytelling = 4
            r.analyticalReasoningAndProblemSolving = 2
            // non-essential
            r.selfDisciplineAndStudyHabits = 2
            r.timeManagementAndPlanning = 1
            r.adaptabilityAndLearningAgility = 1

        case .law:
            r.analyticalReasoningAndProblemSolving = 4
            r.communicationAndNetworking = 4
            r.carefulnessAndAttentionToDetail = 4
            r.patienceAndPerseverance = 4
            r.presentationAndStorytelling = 4
            // non-essential
            r.timeManagementAndPlanning = 2
            r.leadershipAndInfluence = 1
            r.selfDisciplineAndStudyHabits = 1

        case .service:
            r.communicationAndNetworking = 4
            r.stressResistanceAndEmotionalRegulation = 4
            r.collaborationAndTeamwork = 4
            r.timeManagementAndPlanning = 2
            r.patienceAndPerseverance = 2
            // non-essential
            r.presentationAndStorytelling = 1
            r.courageAndRiskTolerance = 1
            r.adaptabilityAndLearningAgility = 1
        }

        return r
    }

    private static func elevated(_ r: Requirements, by delta: Int) -> Requirements {
        var x = r
        func bump(_ v: Int) -> Int { v > 0 ? min(v + delta, 5) : 0 }

        x.analyticalReasoningAndProblemSolving = bump(x.analyticalReasoningAndProblemSolving)
        x.creativityAndInsightfulThinking = bump(x.creativityAndInsightfulThinking)
        x.communicationAndNetworking = bump(x.communicationAndNetworking)
        x.leadershipAndInfluence = bump(x.leadershipAndInfluence)
        x.courageAndRiskTolerance = bump(x.courageAndRiskTolerance)
        x.spacialNavigationAndOrientation = bump(x.spacialNavigationAndOrientation)
        x.carefulnessAndAttentionToDetail = bump(x.carefulnessAndAttentionToDetail)
        x.patienceAndPerseverance = bump(x.patienceAndPerseverance)
        x.tinkeringAndFingerPrecision = bump(x.tinkeringAndFingerPrecision)
        x.physicalStrengthAndEndurance = bump(x.physicalStrengthAndEndurance)
        x.coordinationAndBalance = bump(x.coordinationAndBalance)
        x.stressResistanceAndEmotionalRegulation = bump(x.stressResistanceAndEmotionalRegulation)
        x.outdoorAndWeatherResilience = bump(x.outdoorAndWeatherResilience)
        x.collaborationAndTeamwork = bump(x.collaborationAndTeamwork)
        x.timeManagementAndPlanning = bump(x.timeManagementAndPlanning)
        x.selfDisciplineAndStudyHabits = bump(x.selfDisciplineAndStudyHabits)
        x.adaptabilityAndLearningAgility = bump(x.adaptabilityAndLearningAgility)
        x.presentationAndStorytelling = bump(x.presentationAndStorytelling)

        return x
    }

    private static func enforceMinimums(_ r: Requirements, for level: Level.Stage, profile: TertiaryProfile) -> Requirements {
        var x = r

        // General escalation by level (keep within 5)
        switch level {
        case .Vocational:
            break
        case .Bachelor:
            if profile.isSTEM {
                x.analyticalReasoningAndProblemSolving = min(max(x.analyticalReasoningAndProblemSolving, x.analyticalReasoningAndProblemSolving > 0 ? 3 : 0), 5)
                x.carefulnessAndAttentionToDetail = min(max(x.carefulnessAndAttentionToDetail, x.carefulnessAndAttentionToDetail > 0 ? 2 : 0), 5)
                x.patienceAndPerseverance = min(max(x.patienceAndPerseverance, x.patienceAndPerseverance > 0 ? 2 : 0), 5)
            }
        case .Master:
            if profile.isSTEM {
                x.analyticalReasoningAndProblemSolving = min(max(x.analyticalReasoningAndProblemSolving, x.analyticalReasoningAndProblemSolving > 0 ? 4 : 0), 5)
            } else {
                x.analyticalReasoningAndProblemSolving = min(max(x.analyticalReasoningAndProblemSolving, x.analyticalReasoningAndProblemSolving > 0 ? 3 : 0), 5)
            }
            x.patienceAndPerseverance = min(max(x.patienceAndPerseverance, x.patienceAndPerseverance > 0 ? 3 : 0), 5)
        case .Doctorate:
            if profile.isSTEM {
                x.analyticalReasoningAndProblemSolving = min(max(x.analyticalReasoningAndProblemSolving, x.analyticalReasoningAndProblemSolving > 0 ? 5 : 0), 5)
            } else {
                x.analyticalReasoningAndProblemSolving = min(max(x.analyticalReasoningAndProblemSolving, x.analyticalReasoningAndProblemSolving > 0 ? 4 : 0), 5)
            }
            x.patienceAndPerseverance = min(max(x.patienceAndPerseverance, x.patienceAndPerseverance > 0 ? 4 : 0), 5)
            x.selfDisciplineAndStudyHabits = min(max(x.selfDisciplineAndStudyHabits, x.selfDisciplineAndStudyHabits > 0 ? 3 : 0), 5)
        default:
            break
        }

        // Profile-specific tuning (keep within 5)
        switch profile {
        case .arts, .design:
            if level == .Master || level == .Doctorate {
                x.creativityAndInsightfulThinking = min(max(x.creativityAndInsightfulThinking, x.creativityAndInsightfulThinking > 0 ? (level == .Doctorate ? 5 : 4) : 0), 5)
                x.presentationAndStorytelling = min(max(x.presentationAndStorytelling, x.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .education:
            if level == .Bachelor || level == .Master || level == .Doctorate {
                x.stressResistanceAndEmotionalRegulation = min(max(x.stressResistanceAndEmotionalRegulation, x.stressResistanceAndEmotionalRegulation > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
                x.presentationAndStorytelling = min(max(x.presentationAndStorytelling, x.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .health:
            if level == .Bachelor || level == .Master || level == .Doctorate {
                x.communicationAndNetworking = min(max(x.communicationAndNetworking, x.communicationAndNetworking > 0 ? 3 : 0), 5)
                x.carefulnessAndAttentionToDetail = min(max(x.carefulnessAndAttentionToDetail, x.carefulnessAndAttentionToDetail > 0 ? 3 : 0), 5)
                x.physicalStrengthAndEndurance = min(max(x.physicalStrengthAndEndurance, x.physicalStrengthAndEndurance > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
                x.stressResistanceAndEmotionalRegulation = min(max(x.stressResistanceAndEmotionalRegulation, x.stressResistanceAndEmotionalRegulation > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .business, .law, .humanities:
            if level == .Master || level == .Doctorate {
                x.presentationAndStorytelling = min(max(x.presentationAndStorytelling, x.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        default:
            break
        }

        return x
    }

    private static func clamped(_ r: Requirements) -> Requirements {
        var x = r
        func cap(_ v: Int) -> Int { min(max(0, v), 5) }

        x.analyticalReasoningAndProblemSolving = cap(x.analyticalReasoningAndProblemSolving)
        x.creativityAndInsightfulThinking = cap(x.creativityAndInsightfulThinking)
        x.communicationAndNetworking = cap(x.communicationAndNetworking)
        x.leadershipAndInfluence = cap(x.leadershipAndInfluence)
        x.courageAndRiskTolerance = cap(x.courageAndRiskTolerance)
        x.spacialNavigationAndOrientation = cap(x.spacialNavigationAndOrientation)
        x.carefulnessAndAttentionToDetail = cap(x.carefulnessAndAttentionToDetail)
        x.patienceAndPerseverance = cap(x.patienceAndPerseverance)
        x.tinkeringAndFingerPrecision = cap(x.tinkeringAndFingerPrecision)
        x.physicalStrengthAndEndurance = cap(x.physicalStrengthAndEndurance)
        x.coordinationAndBalance = cap(x.coordinationAndBalance)
        x.stressResistanceAndEmotionalRegulation = cap(x.stressResistanceAndEmotionalRegulation)
        x.outdoorAndWeatherResilience = cap(x.outdoorAndWeatherResilience)
        x.collaborationAndTeamwork = cap(x.collaborationAndTeamwork)
        x.timeManagementAndPlanning = cap(x.timeManagementAndPlanning)
        x.selfDisciplineAndStudyHabits = cap(x.selfDisciplineAndStudyHabits)
        x.adaptabilityAndLearningAgility = cap(x.adaptabilityAndLearningAgility)
        x.presentationAndStorytelling = cap(x.presentationAndStorytelling)

        return x
    }
}

func availableNextEducations(holds: [Education]) -> [Education] {
    var available: [Education] = []
    for profile in TertiaryProfile.allCases {
        let bachelor = Education(.Bachelor, profile: profile)
        available.append(bachelor)
        if profile.allowsVocational {
            let vocational = Education(.Vocational, profile: profile)
            available.append(vocational)
        }
    }

    let bachelorDegrees = holds.filter { $0.level == .Bachelor }
    for bachelor in bachelorDegrees {
        if let profile = bachelor.profile {
            let master = Education(.Master, profile: profile)
            available.append(master)
        }
    }

    let masterDegrees = holds.filter { $0.level == .Master }
    for master in masterDegrees {
        if let profile = master.profile {
            let doctorate = Education(.Doctorate, profile: profile)
            available.append(doctorate)
        }
    }

    return available
}

