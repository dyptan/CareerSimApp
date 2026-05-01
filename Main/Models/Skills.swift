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
        set { HardSkills.syncLevels(&portfolioLevels, to: newValue) }
    }

    var certifications: Set<Certification> {
        get { Set(certificationLevels.keys) }
        set { HardSkills.syncLevels(&certificationLevels, to: newValue) }
    }

    var software: Set<Software> {
        get { Set(softwareLevels.keys) }
        set { HardSkills.syncLevels(&softwareLevels, to: newValue) }
    }

    var licenses: Set<License> {
        get { Set(licenseLevels.keys) }
        set { HardSkills.syncLevels(&licenseLevels, to: newValue) }
    }

    // MARK: - Initializer

    init(
        portfolioItems: Set<Project> = [],
        certifications: Set<Certification> = [],
        software: Set<Software> = [],
        licenses: Set<License> = []
    ) {
        self.portfolioLevels = Dictionary(uniqueKeysWithValues: portfolioItems.map { ($0, .level1) })
        self.certificationLevels = Dictionary(uniqueKeysWithValues: certifications.map { ($0, .level1) })
        self.softwareLevels = Dictionary(uniqueKeysWithValues: software.map { ($0, .level1) })
        self.licenseLevels = Dictionary(uniqueKeysWithValues: licenses.map { ($0, .level1) })
    }

    // MARK: - Private helper

    private static func syncLevels<T: Hashable>(_ dict: inout [T: ProficiencyLevel], to newSet: Set<T>) {
        for key in Array(dict.keys) where !newSet.contains(key) { dict.removeValue(forKey: key) }
        for key in newSet where dict[key] == nil { dict[key] = .level1 }
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
    var visionaryThinkingAndAmbition: Int = 0
    var carefulnessAndAttentionToDetail: Int = 0
    var tinkeringAndFingerPrecision: Int = 0
    var spacialNavigationAndOrientation: Int = 0
    var resilienceAndEndurance: Int = 0
    var stressResistanceAndEmotionalRegulation: Int = 0
    var outdoorAndWeatherResilience: Int = 0
    var collaborationAndTeamwork: Int = 0
    var timeManagementAndPlanning: Int = 0
    var selfDisciplineAndPerseverance: Int = 0
    var presentationAndStorytelling: Int = 0
    
    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String, description: String)] = [
        (\.analyticalReasoningAndProblemSolving, "Hacker", "💡", "Spotting patterns, breaking puzzles into small pieces, and figuring out clever solutions. Useful in math, science, programming, and engineering."),
        (\.creativityAndInsightfulThinking, "Creator", "🎨", "Coming up with new ideas and seeing things in fresh ways. Helpful for design, art, music, marketing, and invention."),
        (\.communicationAndNetworking, "Influencer", "📢", "Talking, writing, listening, and meeting people. Most jobs need this — especially sales, teaching, business, and journalism."),
        (\.leadershipAndInfluence, "Leader", "👑", "Helping a group decide and act together. Used by managers, coaches, founders, and team captains."),
        (\.visionaryThinkingAndAmbition, "Visionary", "🔭", "Imagining big future goals and pulling people toward them. Useful for entrepreneurs, founders, and senior strategists."),
        (\.carefulnessAndAttentionToDetail, "Detective", "🔍", "Catching small mistakes and double-checking everything. Important for accountants, surgeons, editors, and lab work."),
        (\.tinkeringAndFingerPrecision, "Fixer", "🛠️", "Working steadily with your hands on small parts. Used by mechanics, surgeons, watchmakers, and artists."),
        (\.spacialNavigationAndOrientation, "Navigator", "🧭", "Picturing how shapes, spaces, and machines fit together. Useful for engineering, architecture, surgery, and aviation."),
        (\.resilienceAndEndurance, "Athlete", "🏃", "Keeping going through tiredness or stress. Important for nurses, soldiers, athletes, and farmers."),
        (\.stressResistanceAndEmotionalRegulation, "Zen", "☯️", "Staying calm under pressure. Helpful in healthcare, teaching, customer service, and emergency work."),
        (\.collaborationAndTeamwork, "Teamplayer", "🤝", "Sharing work and getting along with others. Almost every job needs this."),
        (\.timeManagementAndPlanning, "Planner", "📅", "Finishing things on time and organising your days. Useful everywhere; vital for project managers and freelancers."),
        (\.selfDisciplineAndPerseverance, "Champion", "🏆", "Sticking with hard work even when it’s boring. Needed for studying, training, and any long career."),
        (\.presentationAndStorytelling, "Storyteller", "📖", "Explaining ideas so others get them. Useful for teaching, sales, journalism, and leadership."),
    ]
    
    private static let _labelMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: skillNames.map { ($0.keyPath as AnyKeyPath, $0.label) })
    private static let _pictogramMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: skillNames.map { ($0.keyPath as AnyKeyPath, $0.pictogram) })
    private static let _descriptionMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: skillNames.map { ($0.keyPath as AnyKeyPath, $0.description) })

    static func label(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _labelMap[keyPath]
    }

    static func pictogram(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _pictogramMap[keyPath]
    }

    static func description(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _descriptionMap[keyPath]
    }
}
// MARK: - Optional: convenience display helpers for a skill + level

extension ProficiencyLevel {
    func formatted(for name: String) -> String {
        "\(name) — \(displayName)"
    }
}

