import Foundation

enum TrainingRequirementResult {
    case ok(cost: Int)
    case blocked(reason: String)
}

enum ProficiencyLevel: Int, Codable, Hashable, CaseIterable, Identifiable, Comparable {
    case level1 = 1
    case level2 = 2
    case level3 = 3

    var id: Int { rawValue }

    // Comparable by raw value
    static func < (lhs: ProficiencyLevel, rhs: ProficiencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .level1: return "Level 1"
        case .level2: return "Level 2"
        case .level3: return "Level 3"
        }
    }

    var next: ProficiencyLevel? {
        switch self {
        case .level1: return .level2
        case .level2: return .level3
        case .level3: return nil
        }
    }
}

// MARK: - Hard skills model (leveled dictionaries + set-facing API)

struct HardSkills: Codable, Hashable {

    private(set) var portfolioLevels: [Project: ProficiencyLevel] = [:]
    private(set) var certificationLevels: [Certification: ProficiencyLevel] = [:]
    private(set) var softwareLevels: [Software: ProficiencyLevel] = [:]
    private(set) var licenseLevels: [License: ProficiencyLevel] = [:]


    var portfolioItems: Set<Project> {
        get { Set(portfolioLevels.keys) }
        set {
            var next = portfolioLevels
            for key in next.keys where !newValue.contains(key) {
                next.removeValue(forKey: key)
            }
            for key in newValue where next[key] == nil {
                next[key] = .level1
            }
            portfolioLevels = next
        }
    }

    var certifications: Set<Certification> {
        get { Set(certificationLevels.keys) }
        set {
            var next = certificationLevels
            for key in next.keys where !newValue.contains(key) {
                next.removeValue(forKey: key)
            }
            for key in newValue where next[key] == nil {
                next[key] = .level1
            }
            certificationLevels = next
        }
    }

    var software: Set<Software> {
        get { Set(softwareLevels.keys) }
        set {
            var next = softwareLevels
            for key in next.keys where !newValue.contains(key) {
                next.removeValue(forKey: key)
            }
            for key in newValue where next[key] == nil {
                next[key] = .level1
            }
            softwareLevels = next
        }
    }

    var licenses: Set<License> {
        get { Set(licenseLevels.keys) }
        set {
            var next = licenseLevels
            for key in next.keys where !newValue.contains(key) {
                next.removeValue(forKey: key)
            }
            for key in newValue where next[key] == nil {
                next[key] = .level1
            }
            licenseLevels = next
        }
    }

    // MARK: - Initializer (keeps Player default working)

    init(
        portfolioItems: Set<Project> = [],
        certifications: Set<Certification> = [],
        software: Set<Software> = [],
        licenses: Set<License> = []
    ) {
        // Default all provided to level1
        self.portfolioLevels = Dictionary(uniqueKeysWithValues: portfolioItems.map { ($0, .level1) })
        self.certificationLevels = Dictionary(uniqueKeysWithValues: certifications.map { ($0, .level1) })
        self.softwareLevels = Dictionary(uniqueKeysWithValues: software.map { ($0, .level1) })
        self.licenseLevels = Dictionary(uniqueKeysWithValues: licenses.map { ($0, .level1) })
    }

    // MARK: - Level accessors

    func level(for item: Project) -> ProficiencyLevel? { portfolioLevels[item] }
    func level(for cert: Certification) -> ProficiencyLevel? { certificationLevels[cert] }
    func level(for sw: Software) -> ProficiencyLevel? { softwareLevels[sw] }
    func level(for lic: License) -> ProficiencyLevel? { licenseLevels[lic] }

    // MARK: - Mutating setters

    
    mutating func setLevel(_ level: ProficiencyLevel, for item: Project) {
        portfolioLevels[item] = level
    }
    mutating func setLevel(_ level: ProficiencyLevel, for cert: Certification) {
        certificationLevels[cert] = level
    }
    mutating func setLevel(_ level: ProficiencyLevel, for sw: Software) {
        softwareLevels[sw] = level
    }
    mutating func setLevel(_ level: ProficiencyLevel, for lic: License) {
        licenseLevels[lic] = level
    }

    // MARK: - Promotion helpers (keeps highest)

    mutating func promote(to level: ProficiencyLevel, for item: Project) {
        portfolioLevels[item] = max(portfolioLevels[item] ?? .level1, level)
    }
    mutating func promote(to level: ProficiencyLevel, for cert: Certification) {
        certificationLevels[cert] = max(certificationLevels[cert] ?? .level1, level)
    }
    mutating func promote(to level: ProficiencyLevel, for sw: Software) {
        softwareLevels[sw] = max(softwareLevels[sw] ?? .level1, level)
    }
    mutating func promote(to level: ProficiencyLevel, for lic: License) {
        licenseLevels[lic] = max(licenseLevels[lic] ?? .level1, level)
    }

    // MARK: - Sequential progression policy (1 level per year)

    private func currentLevel<T: Hashable>(in dict: [T: ProficiencyLevel], for key: T) -> ProficiencyLevel? {
        dict[key]
    }

    private func nextLevel(after level: ProficiencyLevel?) -> ProficiencyLevel? {
        switch level {
        case nil: return .level1
        case .some(let lv): return lv.next
        }
    }

    func isMaxLevel<T: Hashable>(_ key: T, in dict: [T: ProficiencyLevel]) -> Bool {
        (dict[key] ?? .level1) == .level3
    }

    func canTrain(_ item: Project) -> Bool {
        nextLevel(after: currentLevel(in: portfolioLevels, for: item)) != nil
    }
    func canTrain(_ cert: Certification) -> Bool {
        nextLevel(after: currentLevel(in: certificationLevels, for: cert)) != nil
    }
    func canTrain(_ sw: Software) -> Bool {
        nextLevel(after: currentLevel(in: softwareLevels, for: sw)) != nil
    }
    func canTrain(_ lic: License) -> Bool {
        nextLevel(after: currentLevel(in: licenseLevels, for: lic)) != nil
    }


    @discardableResult
    mutating func trainOneYear(_ item: Project) -> ProficiencyLevel? {
        let next = nextLevel(after: portfolioLevels[item])
        if let n = next {
            portfolioLevels[item] = n
        }
        return portfolioLevels[item]
    }
    @discardableResult
    mutating func trainOneYear(_ cert: Certification) -> ProficiencyLevel? {
        let next = nextLevel(after: certificationLevels[cert])
        if let n = next {
            certificationLevels[cert] = n
        }
        return certificationLevels[cert]
    }
    @discardableResult
    mutating func trainOneYear(_ sw: Software) -> ProficiencyLevel? {
        let next = nextLevel(after: softwareLevels[sw])
        if let n = next {
            softwareLevels[sw] = n
        }
        return softwareLevels[sw]
    }
    @discardableResult
    mutating func trainOneYear(_ lic: License) -> ProficiencyLevel? {
        let next = nextLevel(after: licenseLevels[lic])
        if let n = next {
            licenseLevels[lic] = n
        }
        return licenseLevels[lic]
    }

    // MARK: - Removal

    mutating func remove(_ item: Project) { portfolioLevels.removeValue(forKey: item) }
    mutating func remove(_ cert: Certification) { certificationLevels.removeValue(forKey: cert) }
    mutating func remove(_ sw: Software) { softwareLevels.removeValue(forKey: sw) }
    mutating func remove(_ lic: License) { licenseLevels.removeValue(forKey: lic) }
}

struct SoftSkills: Codable, Hashable {
    var analyticalReasoningAndProblemSolving: Int = 0
    var creativityAndInsightfulThinking: Int = 0
    var communicationAndNetworking: Int = 0
    var leadershipAndInfluence: Int = 0
    var courageAndRiskTolerance: Int = 0
    var carefulnessAndAttentionToDetail: Int = 0
    var tinkeringAndFingerPrecision: Int = 0
    var spacialNavigationAndOrientation: Int = 0
    var physicalStrengthAndEndurance: Int = 0
    var stressResistanceAndEmotionalRegulation: Int = 0
    var outdoorAndWeatherResilience: Int = 0
    var patienceAndPerseverance: Int = 0
    var collaborationAndTeamwork: Int = 0
    var timeManagementAndPlanning: Int = 0
    var selfDisciplineAndStudyHabits: Int = 0
    var presentationAndStorytelling: Int = 0
    
    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String)] = [
        (\.analyticalReasoningAndProblemSolving, "Solver", "💡"),
        (\.creativityAndInsightfulThinking, "Creator", "🎨"),
        (\.communicationAndNetworking, "Influencer", "📢"),
        (\.leadershipAndInfluence, "Leader", "👑"),
        (\.courageAndRiskTolerance, "Risk-taker", "🎲"),
        (\.carefulnessAndAttentionToDetail, "Inspector", "🔍"),
        (\.tinkeringAndFingerPrecision, "Fixer", "🛠️"),
        (\.spacialNavigationAndOrientation, "Navigator", "🧭"),
        (\.physicalStrengthAndEndurance, "Athlete", "💪"),
        (\.patienceAndPerseverance, "Striver", "🚀"),
        (\.outdoorAndWeatherResilience, "Scout", "🌧️"),
        (\.stressResistanceAndEmotionalRegulation, "Peacemaker", "🕊️"),
        (\.collaborationAndTeamwork, "Coach", "🤝"),
        (\.timeManagementAndPlanning, "Planner", "📅"),
        (\.selfDisciplineAndStudyHabits, "Achiever", "🏆"),
        (\.presentationAndStorytelling, "Storyteller", "📖")
    ]
    
    static func label(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        for entry in SoftSkills.skillNames {
            let pkp = entry.keyPath as PartialKeyPath<SoftSkills>
            if pkp == keyPath {
                return entry.label
            }
        }
        return nil
    }

    static func pictogram(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        for entry in SoftSkills.skillNames {
            let pkp = entry.keyPath as PartialKeyPath<SoftSkills>
            if pkp == keyPath {
                return entry.pictogram
            }
        }
        return nil
    }
}
// MARK: - Optional: convenience display helpers for a skill + level

extension ProficiencyLevel {
    func formatted(for name: String) -> String {
        "\(name) — \(displayName)"
    }
}

