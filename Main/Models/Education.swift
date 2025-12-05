// Level.swift

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
        case .law: return "Learn rules and how to keep things fair."
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

    struct Requirements: Codable, Hashable {
        var minEQF: Int = 0

        // Soft skills thresholds (mirrors JobView names)
        var analyticalReasoning: Int = 0
        var creativeExpression: Int = 0
        var socialCommunication: Int = 0
        var leadershipAndInfluence: Int = 0
        var riskTolerance: Int = 0
        var spatialThinking: Int = 0
        var attentionToDetail: Int = 0
        var perseveranceAndGrit: Int = 0
        var tinkering: Int = 0
        var physicalStrength: Int = 0
        var endurance: Int = 0

        // New school-age soft skills thresholds
        var emotionalIntelligence: Int = 0
        var collaborationAndTeamwork: Int = 0
        var timeManagementAndPlanning: Int = 0
        var selfDisciplineAndStudyHabits: Int = 0
        var adaptabilityAndLearningAgility: Int = 0
        var presentationAndStorytelling: Int = 0
    }

    var requirements: Requirements {
        switch (level, profile) {
        case (.Vocational, .some(let p)):
            switch p {
            case .technology:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 1,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 0,
                    tinkering: 1,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .engineering:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 1,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 1,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 1,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .health:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 1,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .agriculture:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 1,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .design:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 1,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .sports:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 1,
                    endurance: 1,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 1,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .service:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 1,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            default:
                return Requirements(minEQF: 3)
            }

        case (.Bachelor, .some(let p)):
            switch p {
            case .engineering:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 2,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 1,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .technology:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 2,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .science:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 2,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 1,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .arts:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 2,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .design:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 2,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .business:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 1,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .education:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 1,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .health:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 1,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 1,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .humanities:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .law:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 1,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 1
                )
            case .agriculture:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 1,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 1,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 1,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .sports:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 0,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 1,
                    endurance: 1,
                    emotionalIntelligence: 0,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 1,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            case .service:
                return Requirements(
                    minEQF: 3,
                    analyticalReasoning: 0,
                    creativeExpression: 0,
                    socialCommunication: 1,
                    leadershipAndInfluence: 0,
                    riskTolerance: 0,
                    spatialThinking: 0,
                    attentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkering: 0,
                    physicalStrength: 0,
                    endurance: 0,
                    emotionalIntelligence: 1,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndStudyHabits: 0,
                    adaptabilityAndLearningAgility: 0,
                    presentationAndStorytelling: 0
                )
            }

        case (.Master, .some(let p)):
            var base = Education(.Bachelor, profile: p).requirements
            base.minEQF = 5
            base.analyticalReasoning = max(base.analyticalReasoning, 2)
            base.creativeExpression = max(base.creativeExpression, 2)
            base.perseveranceAndGrit = max(base.perseveranceAndGrit, 2)
            return base

        case (.Doctorate, .some(let p)):
            var base = Education(.Master, profile: p).requirements
            base.minEQF = 6
            base.perseveranceAndGrit = max(base.perseveranceAndGrit, 2)
            base.analyticalReasoning = max(base.analyticalReasoning, 2)
            return base

        default:
            return Requirements()
        }
    }

    func meetsRequirements(player: Player) -> Bool {
        let p = player.softSkills
        let highestEQF = player.degrees.last?.eqf ?? 0
        let r = requirements

        guard highestEQF >= r.minEQF else { return false }
        guard p.analyticalReasoningAndProblemSolving >= r.analyticalReasoning else { return false }
        guard p.creativityAndInsightfulThinking >= r.creativeExpression else { return false }
        guard p.communicationAndNetworking >= r.socialCommunication else { return false }
        guard p.leadershipAndInfluence >= r.leadershipAndInfluence else { return false }
        guard p.courageAndRiskTolerance >= r.riskTolerance else { return false }
        guard p.spacialNavigation >= r.spatialThinking else { return false }
        guard p.carefulnessAndAttentionToDetail >= r.attentionToDetail else { return false }
        guard p.perseveranceAndGrit >= r.perseveranceAndGrit else { return false }
        guard p.tinkeringAndFingerPrecision >= r.tinkering else { return false }
        guard p.physicalStrength >= r.physicalStrength else { return false }
        guard p.resilienceAndEndurance >= r.endurance else { return false }

        guard p.emotionalIntelligence >= r.emotionalIntelligence else { return false }
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
