import Foundation
import SwiftUI

final class Player: ObservableObject {
    @Published var age: Int
    @Published var degrees: [Education]
    /// Years of work experience per industry. Key is the job's `JobCategory`,
    /// value is total years accumulated across all jobs in that industry.
    @Published var experience: [JobCategory: Int]
    @Published var softSkills: SoftSkills
    @Published var hardSkills: HardSkills
    @Published var currentOccupation: Job?
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedCertifications: Set<Certification>
    @Published var lockedPortfolio: Set<Project>
    @Published var lockedLicenses: Set<License>
    @Published var lockedActivities: Set<String>
    @Published var appliedJobIds: Set<String> = []
    /// Jobs offered to the player this year. Re-shuffled (and re-rolled for
    /// company tier / salary variance) every time `advanceYear` runs, so the
    /// listing feels different each game year.
    @Published var availableJobs: [Job] = []

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
        experience: [JobCategory: Int] = [:],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedCertifications: Set<Certification> = [],
        lockedPortfolio: Set<Project> = [],
        lockedLicenses: Set<License> = [],
        lockedActivities: Set<String> = []
    ) {
        self.age = age
        self.softSkills = softSkills
        self.hardSkills = hardSkills
        self.degrees = degrees
        self.experience = experience
        self.currentOccupation = currentOccupation
        self.currentEducation = Education(Level.Stage.PrimarySchool)
        self.savings = savings
        self.lockedCertifications = lockedCertifications
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
        self.lockedActivities = lockedActivities
        self.availableJobs = JobCatalog.allJobs().shuffled()
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

    // MARK: - Year progression

    func advanceYear(appUIState: AppUIState) {
        age += 1

        hardSkills.certifications.formUnion(appUIState.selectedCertifications)
        hardSkills.licenses.formUnion(appUIState.selectedLicenses)
        hardSkills.portfolioItems.formUnion(appUIState.selectedPortfolio)

        lockedCertifications.formUnion(appUIState.selectedCertifications)
        lockedPortfolio.formUnion(appUIState.selectedPortfolio)
        lockedLicenses.formUnion(appUIState.selectedLicenses)

        appUIState.selectedActivities.removeAll()

        // Charge tuition for the year the player is enrolled in a tertiary program.
        if let edu = currentEducation,
           let yearsLeft = appUIState.yearsLeftToGraduation,
           yearsLeft > 0,
           edu.profile != nil {
            savings -= edu.annualTuition
        }

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

        appliedJobIds.removeAll()
        availableJobs = JobCatalog.allJobs().shuffled()

        if let job = currentOccupation {
            currentOccupation?.companyTier = CompanyTier.random(category: job.category, income: job.income)
            savings += job.annualIncome
            experience[job.category, default: 0] += 1
        }
    }

    /// Applies for a job at the given salary. Returns true if hired.
    /// Side effects: marks the job as applied; if hired, sets currentOccupation with the agreed salary.
    @discardableResult
    func applyForJob(_ job: Job, requestedSalary: Int) -> Bool {
        appliedJobIds.insert(job.id)
        let probability = job.hireProbability(for: self, requestedSalary: Double(requestedSalary))
        let hired = Double.random(in: 0...1) < probability
        if hired {
            var hiredJob = job
            hiredJob.annualIncome = requestedSalary
            currentOccupation = hiredJob
        }
        return hired
    }

    func reset() {
        let fresh = Player()
        age = fresh.age
        softSkills = fresh.softSkills
        hardSkills = fresh.hardSkills
        degrees = fresh.degrees
        experience = fresh.experience
        currentOccupation = fresh.currentOccupation
        currentEducation = fresh.currentEducation
        savings = fresh.savings
        lockedCertifications = fresh.lockedCertifications
        lockedPortfolio = fresh.lockedPortfolio
        lockedLicenses = fresh.lockedLicenses
        lockedActivities = fresh.lockedActivities
        appliedJobIds = []
        availableJobs = fresh.availableJobs
    }
}

