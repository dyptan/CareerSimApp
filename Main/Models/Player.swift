import Foundation
import SwiftUI

final class Player: ObservableObject {
    @Published var age: Int
    @Published var degrees: [Education]
    @Published var jobExperiance: [(Job, Int)]
    @Published var softSkills: SoftSkills
    @Published var hardSkills: HardSkills
    @Published var hardSkillLevels: [Certification: Int]
    @Published var currentOccupation: Job?
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedCertifications: Set<Certification>
    @Published var lockedSoftware: Set<Software>
    @Published var lockedPortfolio: Set<Project>
    @Published var lockedLicenses: Set<License>
    @Published var lockedActivities: Set<String>

    init(
        age: Int = 7,
        softSkills: SoftSkills = SoftSkills(
            analyticalReasoningAndProblemSolving: Int.random(in: 0...1),
            creativityAndInsightfulThinking: Int.random(in: 0...1),
            communicationAndNetworking: Int.random(in: 0...1),
            leadershipAndInfluence: Int.random(in: 0...1),
            courageAndRiskTolerance: Int.random(in: 0...1),
            carefulnessAndAttentionToDetail: Int.random(in: 0...1),
            tinkeringAndFingerPrecision: Int.random(in: 0...1),
            spacialNavigationAndOrientation: Int.random(in: 0...1),
            physicalStrengthAndEndurance: Int.random(in: 0...1),
            stressResistanceAndEmotionalRegulation: Int.random(in: 0...1),
            outdoorAndWeatherResilience: Int.random(in: 0...1),
            patienceAndPerseverance: Int.random(in: 0...1),
            collaborationAndTeamwork: Int.random(in: 0...1),
            timeManagementAndPlanning: Int.random(in: 0...1),
            selfDisciplineAndStudyHabits: Int.random(in: 0...1),
            presentationAndStorytelling: Int.random(in: 0...1)
        ),
        hardSkills: HardSkills = HardSkills(
            portfolioItems: [],
            certifications: [],
            software: [],
            licenses: []
        ),
        hardSkillLevels: [Certification: Int] = [:],
        degrees: [Education] = [],
        jobExperiance: [(Job, Int)] = [],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedCertifications: Set<Certification> = [],
        lockedSoftware: Set<Software> = [],
        lockedPortfolio: Set<Project> = [],
        lockedLicenses: Set<License> = [],
        lockedActivities: Set<String> = []
    ) {
        self.age = age
        self.softSkills = softSkills
        self.hardSkills = hardSkills
        self.hardSkillLevels = hardSkillLevels
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

extension Player {
    @MainActor
    func apply(selectedActivities: Set<String>, from activities: [Activity]) {
        print("[Activities] Applying \(selectedActivities.count) activities: \(Array(selectedActivities))")
        var updated = softSkills
        var totalDelta = 0
        for activity in activities where selectedActivities.contains(activity.label) {
            for ability in activity.abilities {
                updated[keyPath: ability.keyPath] += ability.weight
                totalDelta += ability.weight
            }
        }
        print("[Activities] Total skill delta: \(totalDelta)")
        objectWillChange.send()
        withAnimation {
            softSkills = updated
        }
        print("[Activities] Applied. Soft skills updated.")
    }
}

