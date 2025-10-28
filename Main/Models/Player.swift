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

    init(
        age: Int = 7,
        abilities: SoftSkills = SoftSkills(
            analyticalReasoning: Int.random(in: 0..<3),
            creativeExpression: Int.random(in: 0..<3),
            socialCommunication: Int.random(in: 0..<3),
            teamLeadership: Int.random(in: 0..<3),
            influenceAndNetworking: Int.random(in: 0..<3),
            riskTolerance: Int.random(in: 0..<3),
            spatialThinking: Int.random(in: 0..<3),
            attentionToDetail: Int.random(in: 0..<3),
            resilienceCognitive: Int.random(in: 0..<3),
            mechanicalOperation: Int.random(in: 0..<3),
            physicalAbility: 0,
            resiliencePhysical: 0
        ),
        hardSkills: HardSkills = HardSkills(
            languages: [.ukrainian],
            portfolioItems: [],
            certifications: [],
            software: [.macOS],
            licenses: []
        ),
        degrees: [(TertiaryProfile?, Level)] = [],
        jobExperiance: [(Job, Int)] = [],
        currentOccupation: Job? = nil,
        savings: Int = 0
    ) {
        self.age = age
        self.softSkills = abilities
        self.hardSkills = hardSkills
        self.degrees = degrees
        self.jobExperiance = jobExperiance
        self.currentOccupation = currentOccupation
        self.savings = savings
    }

    func boostAbility(_ keyPath: WritableKeyPath<SoftSkills, Int>) {
        softSkills[keyPath: keyPath] += 1
    }
}
