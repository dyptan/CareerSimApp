import SwiftUI
import Combine

final class AppUIState: ObservableObject {
    // Sheets
    @Published var showDecisionSheet: Bool
    @Published var showTertiarySheet: Bool
    @Published var showCareersSheet: Bool
    @Published var showProjectsSheet: Bool = false
    @Published var showActivitiesSheet: Bool = false
    @Published var showCertificationsSheet: Bool = false
    @Published var showLicensesSheet: Bool = false
    @Published var showRetirementSheet: Bool = false

    // Selections
    @Published var selectedActivities: Set<String>
    @Published var selectedLicenses: Set<License>
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
        selectedLicenses: Set<License> = [],
        selectedPortfolio: Set<Project> = [],
        selectedCertifications: Set<Certification> = [],
        yearsLeftToGraduation: Int? = nil,
        decisionText: String = "",
        showProjectsSheet: Bool = false,
        showActivitiesSheet: Bool = false,
        showCertificationsSheet: Bool = false,
        showLicensesSheet: Bool = false,
        showRetirementSheet: Bool = false
    ) {
        self.showDecisionSheet = showDecisionSheet
        self.showTertiarySheet = showTertiarySheet
        self.showCareersSheet = showCareersSheet
        self.selectedActivities = selectedActivities
        self.selectedLicenses = selectedLicenses
        self.selectedPortfolio = selectedPortfolio
        self.selectedCertifications = selectedCertifications
        self.yearsLeftToGraduation = yearsLeftToGraduation
        self.decisionText = decisionText
        self.showProjectsSheet = showProjectsSheet
        self.showActivitiesSheet = showActivitiesSheet
        self.showCertificationsSheet = showCertificationsSheet
        self.showLicensesSheet = showLicensesSheet
        self.showRetirementSheet = showRetirementSheet
    }

    func reset() {
        showDecisionSheet = false
        showTertiarySheet = false
        showCareersSheet = true
        showProjectsSheet = false
        showActivitiesSheet = false
        showCertificationsSheet = false
        showLicensesSheet = false
        showRetirementSheet = false
        selectedActivities = []
        selectedLicenses = []
        selectedPortfolio = []
        selectedCertifications = []
        yearsLeftToGraduation = nil
        decisionText = ""
    }
}
