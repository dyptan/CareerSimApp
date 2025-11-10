import Foundation

final class Player: ObservableObject {
    @Published var age: Int
    @Published var degrees: [(TertiaryProfile?, Level)]
    @Published var jobExperiance: [(Job, Int)]
    @Published var softSkills: SoftSkills
    @Published var hardSkills: HardSkills
    @Published var currentOccupation: Job?
    @Published var currentEducation: (TertiaryProfile, Level)?
    @Published var savings: Int
    @Published var lockedCertifications: Set<Certification>
    @Published var lockedLanguages: Set<Language>
    @Published var lockedSoftware: Set<Software>
    @Published var lockedPortfolio: Set<PortfolioItem>
    @Published var lockedLicenses: Set<License>

    init(
        age: Int = 7,
        abilities: SoftSkills = SoftSkills(
            problemSolving: Int.random(in: 0..<3),
            creativity: Int.random(in: 0..<3),
            communication: Int.random(in: 0..<3),
            leadershipAndFriends: Int.random(in: 0..<3),
            riskTaking: Int.random(in: 0..<3),
            navigation: Int.random(in: 0..<3),
            carefulness: Int.random(in: 0..<3),
            tinkering: Int.random(in: 0..<3),
            strength: Int.random(in: 0..<3),
            focusAndGrit: Int.random(in: 0..<3),
            stamina: Int.random(in: 0..<3),
            weatherEndurance: Int.random(in: 0..<3),
            entrepreneurship: Int.random(in: 0..<3)
        ),
        hardSkills: HardSkills = HardSkills(
            languages: [],
            portfolioItems: [],
            certifications: [],
            software: [],
            licenses: []
        ),
        degrees: [(TertiaryProfile?, Level)] = [],
        jobExperiance: [(Job, Int)] = [],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedCertifications: Set<Certification> = [],
        lockedLanguages: Set<Language> = [],
        lockedSoftware: Set<Software> = [],
        lockedPortfolio: Set<PortfolioItem> = [],
        lockedLicenses: Set<License> = []
    ) {
        self.age = age
        self.softSkills = abilities
        self.hardSkills = hardSkills
        self.degrees = degrees
        self.jobExperiance = jobExperiance
        self.currentOccupation = currentOccupation
        self.savings = savings
        self.lockedCertifications = lockedCertifications
        self.lockedLanguages = lockedLanguages
        self.lockedSoftware = lockedSoftware
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
    }

    func boostAbility(_ keyPath: WritableKeyPath<SoftSkills, Int>) {
        softSkills[keyPath: keyPath] += 1
    }
}
