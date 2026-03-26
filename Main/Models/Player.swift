import Foundation
import SwiftUI

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
            resilienceAndEndurance: Int.random(in: 0...1),
            stressResistanceAndEmotionalRegulation: Int.random(in: 0...1),
            outdoorAndWeatherResilience: Int.random(in: 0...1),
            patienceAndPerseverance: Int.random(in: 0...1),
            collaborationAndTeamwork: Int.random(in: 0...1),
            timeManagementAndPlanning: Int.random(in: 0...1),
            selfDisciplineAndPerseverance: Int.random(in: 0...1),
            presentationAndStorytelling: Int.random(in: 0...1)
        ),
        hardSkills: HardSkills = HardSkills(),
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
        self.degrees = degrees
        self.jobExperiance = jobExperiance
        self.currentOccupation = currentOccupation
        self.currentEducation = nil
        self.savings = savings
        self.lockedCertifications = lockedCertifications
        self.lockedSoftware = lockedSoftware
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
        self.lockedActivities = lockedActivities
    }

    func reset() {
        let fresh = Player()
        age = fresh.age
        softSkills = fresh.softSkills
        hardSkills = fresh.hardSkills
        degrees = fresh.degrees
        jobExperiance = fresh.jobExperiance
        currentOccupation = fresh.currentOccupation
        currentEducation = fresh.currentEducation
        savings = fresh.savings
        lockedCertifications = fresh.lockedCertifications
        lockedSoftware = fresh.lockedSoftware
        lockedPortfolio = fresh.lockedPortfolio
        lockedLicenses = fresh.lockedLicenses
        lockedActivities = fresh.lockedActivities
    }
}

