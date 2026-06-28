import SwiftUI
import Combine

final class AppUIState: ObservableObject {
    // Sheets
    @Published var showDecisionSheet: Bool
    @Published var showTertiarySheet: Bool
    @Published var showCareersSheet: Bool
    @Published var showHobbiesSheet: Bool = false
    @Published var showCertificationsSheet: Bool = false
    @Published var showLicensesSheet: Bool = false
    @Published var showSideHustlesSheet: Bool = false
    @Published var showEventsSheet: Bool = false
    @Published var showCompetitionsSheet: Bool = false
    @Published var showSportsSheet: Bool = false
    @Published var showClubsSheet: Bool = false
    @Published var showRetirementSheet: Bool = false

    // Selections
    @Published var selectedActivities: Set<String>
    @Published var selectedLicenses: Set<License>
    @Published var selectedCertifications: Set<Certification>
    /// Ids of the side hustles the player is attempting this year (see
    /// `SideHustleCatalog`). Resolved and cleared by `Player.advanceYear`.
    @Published var selectedSideHustles: Set<String> = []
    /// Ids of the professional events the player is attending this year (see
    /// `EventCatalog`). Their cost/effects apply on attendance; cleared by
    /// `Player.advanceYear`.
    @Published var selectedEvents: Set<String> = []
    /// Ids of the competitions the player is entering this year (see
    /// `CompetitionCatalog`). Resolved and cleared by `Player.advanceYear`.
    @Published var selectedCompetitions: Set<String> = []
    /// Sports the player is committing this year's spare-time slot to.
    /// Banked into `Player.sportYears` and cleared by `Player.advanceYear`.
    @Published var selectedSports: Set<Sport> = []

    // Misc
    @Published var yearsLeftToGraduation: Int?
    @Published var decisionText: String

    /// Whether the player has picked a game mode yet. Until true, RootView shows
    /// the mode picker instead of the game. Reset to false on restart.
    @Published var hasSelectedMode: Bool = false

    /// Drives the goal-reached celebration sheet. `hasShownGoal` guards it so
    /// the celebration only appears once per game.
    @Published var showGoalSheet: Bool = false
    @Published var hasShownGoal: Bool = false


    init(
        showDecisionSheet: Bool = false,
        showTertiarySheet: Bool = false,
        showCareersSheet: Bool = false,
        selectedActivities: Set<String> = [],
        selectedLicenses: Set<License> = [],
        selectedCertifications: Set<Certification> = [],
        yearsLeftToGraduation: Int? = nil,
        decisionText: String = "",
        showHobbiesSheet: Bool = false,
        showCertificationsSheet: Bool = false,
        showLicensesSheet: Bool = false,
        showRetirementSheet: Bool = false
    ) {
        self.showDecisionSheet = showDecisionSheet
        self.showTertiarySheet = showTertiarySheet
        self.showCareersSheet = showCareersSheet
        self.selectedActivities = selectedActivities
        self.selectedLicenses = selectedLicenses
        self.selectedCertifications = selectedCertifications
        self.yearsLeftToGraduation = yearsLeftToGraduation
        self.decisionText = decisionText
        self.showHobbiesSheet = showHobbiesSheet
        self.showCertificationsSheet = showCertificationsSheet
        self.showLicensesSheet = showLicensesSheet
        self.showRetirementSheet = showRetirementSheet
    }

    func reset() {
        showDecisionSheet = false
        showTertiarySheet = false
        showCareersSheet = true
        showHobbiesSheet = false
        showCertificationsSheet = false
        showLicensesSheet = false
        showSideHustlesSheet = false
        showEventsSheet = false
        showCompetitionsSheet = false
        showSportsSheet = false
        showClubsSheet = false
        showRetirementSheet = false
        hasSelectedMode = false
        showGoalSheet = false
        hasShownGoal = false
        selectedActivities = []
        selectedLicenses = []
        selectedCertifications = []
        selectedSideHustles = []
        selectedEvents = []
        selectedCompetitions = []
        selectedSports = []
        yearsLeftToGraduation = nil
        decisionText = ""
    }
}
