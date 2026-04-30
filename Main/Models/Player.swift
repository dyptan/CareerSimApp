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
            visionaryThinkingAndAmbition: Int.random(in: 0...1),
            carefulnessAndAttentionToDetail: Int.random(in: 0...1),
            tinkeringAndFingerPrecision: Int.random(in: 0...1),
            spacialNavigationAndOrientation: Int.random(in: 0...1),
            resilienceAndEndurance: Int.random(in: 0...1),
            stressResistanceAndEmotionalRegulation: Int.random(in: 0...1),
            outdoorAndWeatherResilience: Int.random(in: 0...1),
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
        self.currentEducation = Education(Level.Stage.PrimarySchool)
        self.savings = savings
        self.lockedCertifications = lockedCertifications
        self.lockedSoftware = lockedSoftware
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
        self.lockedActivities = lockedActivities
    }

    // MARK: - Activity selection

    func selectActivity(_ activity: Activity, into selectedActivities: inout Set<String>) {
        selectedActivities.insert(activity.label)
        for ability in activity.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] += ability.weight
        }
    }

    func deselectActivity(_ activity: Activity, from selectedActivities: inout Set<String>) {
        guard selectedActivities.remove(activity.label) != nil else { return }
        for ability in activity.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
    }

    // MARK: - Training purchase / refund

    func purchaseCertification(_ cert: Certification, into selectedCertifications: inout Set<Certification>, activities selectedActivities: inout Set<String>) {
        guard case .ok(let cost) = cert.certificationRequirements(self) else { return }
        selectedCertifications.insert(cert)
        selectedActivities.insert("cert:\(cert.rawValue)")
        savings -= cost
    }

    func refundCertification(_ cert: Certification, from selectedCertifications: inout Set<Certification>, activities selectedActivities: inout Set<String>) {
        guard selectedCertifications.remove(cert) != nil else { return }
        selectedActivities.remove("cert:\(cert.rawValue)")
        savings += cert.costForCertification
    }

    func purchaseLicense(_ lic: License, into selectedLicenses: inout Set<License>, activities selectedActivities: inout Set<String>) {
        guard case .ok(let cost) = lic.licenseRequirements(self) else { return }
        selectedLicenses.insert(lic)
        selectedActivities.insert("lic:\(lic.rawValue)")
        savings -= cost
    }

    func refundLicense(_ lic: License, from selectedLicenses: inout Set<License>, activities selectedActivities: inout Set<String>) {
        guard selectedLicenses.remove(lic) != nil else { return }
        selectedActivities.remove("lic:\(lic.rawValue)")
        savings += lic.costForLicense
    }

    func purchaseSoftware(_ sw: Software, into selectedSoftware: inout Set<Software>, activities selectedActivities: inout Set<String>) {
        guard case .ok(let cost) = sw.softwareRequirements(self) else { return }
        selectedSoftware.insert(sw)
        selectedActivities.insert("soft:\(sw.rawValue)")
        savings -= cost
    }

    func deselectSoftware(_ sw: Software, from selectedSoftware: inout Set<Software>, activities selectedActivities: inout Set<String>) {
        guard selectedSoftware.remove(sw) != nil else { return }
        selectedActivities.remove("soft:\(sw.rawValue)")
    }

    // MARK: - Year progression

    func advanceYear(appUIState: AppUIState) {
        age += 1

        hardSkills.certifications.formUnion(appUIState.selectedCertifications)
        hardSkills.licenses.formUnion(appUIState.selectedLicenses)
        hardSkills.portfolioItems.formUnion(appUIState.selectedPortfolio)
        hardSkills.software.formUnion(appUIState.selectedSoftware)

        lockedCertifications.formUnion(appUIState.selectedCertifications)
        lockedPortfolio.formUnion(appUIState.selectedPortfolio)
        lockedSoftware.formUnion(appUIState.selectedSoftware)
        lockedLicenses.formUnion(appUIState.selectedLicenses)

        appUIState.selectedActivities.removeAll()

        appUIState.yearsLeftToGraduation? -= 1
        if appUIState.yearsLeftToGraduation == 0 {
            appUIState.decisionText = "You're done with your degree! What's your next step?"
            appUIState.showDecisionSheet.toggle()
            if let currentEducation {
                degrees.append(currentEducation)
            }
            appUIState.yearsLeftToGraduation = nil
            currentEducation = nil
        }

        savings += currentOccupation?.income ?? 0
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

