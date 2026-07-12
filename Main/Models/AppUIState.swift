import SwiftUI
import Combine

final class AppUIState: ObservableObject {
    // Sheets
    @Published var showTertiarySheet: Bool
    @Published var showCareersSheet: Bool
    @Published var showHobbiesSheet: Bool = false
    @Published var showTrainingsSheet: Bool = false
    @Published var showSideHustlesSheet: Bool = false
    @Published var showEntrepreneurshipSheet: Bool = false
    /// The Boardroom sheet — senior-leadership strategy plays. Gated in the
    /// footer on the player holding an executive seat (`Job.isExecutive`).
    @Published var showExecutiveSheet: Bool = false
    @Published var showEventsSheet: Bool = false
    @Published var showSportsSheet: Bool = false
    @Published var showRetirementSheet: Bool = false

    // Selections
    @Published var selectedActivities: Set<String>
    /// Trainings the player is attempting this year (former certifications +
    /// licences, now unified). Resolved and cleared by `Player.advanceYear`.
    @Published var selectedTrainings: Set<Training>
    /// Ids of the spare-time ventures (money hustles + fame projects, now one
    /// system) the player is attempting this year (see `SideHustleCatalog`).
    /// Resolved and cleared by `Player.advanceYear`.
    @Published var selectedSideHustles: Set<String> = []
    /// The professional events the player is attending this year, keyed by event
    /// id and mapped to the role (participant/presenter) they're attending in
    /// (see `EventCatalog`). Network/soft-skill effects apply on attendance;
    /// presenter fame is banked — and picks cleared — by `Player.advanceYear`.
    @Published var selectedEvents: [String: EventRole] = [:]
    /// Sports the player is committing this year's spare-time slot to.
    /// Banked into `Player.sportYears` and cleared by `Player.advanceYear`.
    @Published var selectedSports: Set<Sport> = []

    // Misc
    @Published var yearsLeftToGraduation: Int?

    /// Whether the player has picked a game mode yet. Until true, RootView shows
    /// the mode picker instead of the game. Reset to false on restart.
    @Published var hasSelectedMode: Bool = false

    /// Drives the goal-reached celebration sheet. `hasShownGoal` guards it so
    /// the celebration only appears once per game.
    @Published var showGoalSheet: Bool = false
    @Published var hasShownGoal: Bool = false


    init(
        showTertiarySheet: Bool = false,
        showCareersSheet: Bool = false,
        selectedActivities: Set<String> = [],
        selectedTrainings: Set<Training> = [],
        yearsLeftToGraduation: Int? = nil,
        showHobbiesSheet: Bool = false,
        showTrainingsSheet: Bool = false,
        showRetirementSheet: Bool = false
    ) {
        self.showTertiarySheet = showTertiarySheet
        self.showCareersSheet = showCareersSheet
        self.selectedActivities = selectedActivities
        self.selectedTrainings = selectedTrainings
        self.yearsLeftToGraduation = yearsLeftToGraduation
        self.showHobbiesSheet = showHobbiesSheet
        self.showTrainingsSheet = showTrainingsSheet
        self.showRetirementSheet = showRetirementSheet
    }

    func reset() {
        showTertiarySheet = false
        showCareersSheet = true
        showHobbiesSheet = false
        showTrainingsSheet = false
        showSideHustlesSheet = false
        showEntrepreneurshipSheet = false
        showExecutiveSheet = false
        showEventsSheet = false
        showSportsSheet = false
        showRetirementSheet = false
        hasSelectedMode = false
        showGoalSheet = false
        hasShownGoal = false
        selectedActivities = []
        selectedTrainings = []
        selectedSideHustles = []
        selectedEvents = [:]
        selectedSports = []
        yearsLeftToGraduation = nil
    }
}
