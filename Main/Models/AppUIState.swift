import SwiftUI
import Combine

final class AppUIState: ObservableObject {
    // Sheets
    @Published var showDecisionSheet: Bool
    @Published var showTertiarySheet: Bool
    @Published var showCareersSheet: Bool
    @Published var showProjectsSheet: Bool = false
    @Published var showCourcesSheet: Bool = false
    @Published var showSoftSkillsSheet: Bool = false
    @Published var showCertificationsSheet: Bool = false
    @Published var showLicencesSheet: Bool = false
    @Published var showRetirementSheet: Bool = false

    // Selections
    @Published var selectedActivities: Set<String>
    @Published var selectedSoftware: Set<Software>
    @Published var selectedLicences: Set<License>
    @Published var selectedPortfolio: Set<Project>
    @Published var selectedCertifications: Set<Certification>

    // Misc
    @Published var yearsLeftToGraduation: Int?
    @Published var decisionText: String

    init(
        showDecisionSheet: Bool = false,
        showTertiarySheet: Bool = false,
        showCareersSheet: Bool = false,
        selectedActivities: Set<String> = [],
        selectedSoftware: Set<Software> = [],
        selectedLicences: Set<License> = [],
        selectedPortfolio: Set<Project> = [],
        selectedCertifications: Set<Certification> = [],
        yearsLeftToGraduation: Int? = nil,
        decisionText: String = "",
        showProjectsSheet: Bool = false,
        showCourcesSheet: Bool = false,
        showSoftSkillsSheet: Bool = false,
        showCertificationsSheet: Bool = false,
        showLicencesSheet: Bool = false,
        showRetirementSheet: Bool = false
    ) {
        self.showDecisionSheet = showDecisionSheet
        self.showTertiarySheet = showTertiarySheet
        self.showCareersSheet = showCareersSheet
        self.selectedActivities = selectedActivities
        self.selectedSoftware = selectedSoftware
        self.selectedLicences = selectedLicences
        self.selectedPortfolio = selectedPortfolio
        self.selectedCertifications = selectedCertifications
        self.yearsLeftToGraduation = yearsLeftToGraduation
        self.decisionText = decisionText
        self.showProjectsSheet = showProjectsSheet
        self.showCourcesSheet = showCourcesSheet
        self.showSoftSkillsSheet = showSoftSkillsSheet
        self.showCertificationsSheet = showCertificationsSheet
        self.showLicencesSheet = showLicencesSheet
        self.showRetirementSheet = showRetirementSheet
    }
}
