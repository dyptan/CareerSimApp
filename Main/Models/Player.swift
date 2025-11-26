import Foundation

final class Player: ObservableObject {
    @Published var age: Int
    @Published var degrees: [Education]
    @Published var jobExperiance: [(Job, Int)]
    @Published var softSkills: SoftSkills
    @Published var hardSkills: HardSkills
    @Published var currentOccupation: Job?
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedCertifications: Set<Certification>
    @Published var lockedSoftware: Set<Software>
    @Published var lockedPortfolio: Set<PortfolioItem>
    @Published var lockedLicenses: Set<License>
    @Published var lockedActivities: Set<String>

    init(
        age: Int = 7,
        softSkills: SoftSkills = SoftSkills(
            analyticalReasoningAndProblemSolving: Int.random(in: 0..<3),
            creativityAndInsightfulThinking: Int.random(in: 0..<3),
            communicationAndNetworking: Int.random(in: 0..<3),
            leadershipAndInfluence: Int.random(in: 0..<3),
            courageAndRiskTolerance: Int.random(in: 0..<3),
            carefulnessAndAttentionToDetail: Int.random(in: 0..<3),
            tinkeringAndFingerPrecision: Int.random(in: 0..<3),
            spacialNavigation: Int.random(in: 0..<3),
            physicalStrength: Int.random(in: 0..<3),
            coordinationAndBalance: Int.random(in: 0..<3),
            perseveranceAndGrit: Int.random(in: 0..<3),
            resilienceAndEndurance: Int.random(in: 0..<3)
        ),
        hardSkills: HardSkills = HardSkills(
            portfolioItems: [],
            certifications: [],
            software: [],
            licenses: []
        ),
        degrees: [Education] = [],
        jobExperiance: [(Job, Int)] = [],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedCertifications: Set<Certification> = [],
        lockedSoftware: Set<Software> = [],
        lockedPortfolio: Set<PortfolioItem> = [],
        lockedLicenses: Set<License> = [],
        lockedActivities: Set<String> = []
    ) {
        self.age = age
        self.softSkills = softSkills
        self.hardSkills = hardSkills
        self.degrees = degrees
        self.jobExperiance = jobExperiance
        self.currentOccupation = currentOccupation
        self.savings = savings
        self.lockedCertifications = lockedCertifications
        self.lockedSoftware = lockedSoftware
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
        self.lockedActivities = lockedActivities
    }

    func boostAbility(_ keyPath: WritableKeyPath<SoftSkills, Int>) {
        softSkills[keyPath: keyPath] += 1
    }
}

